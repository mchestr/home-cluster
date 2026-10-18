# Disaster Recovery

Notes on backups, restores, and what to do when things go wrong.

## Backup Strategy

- **Persistent Volumes** - Volsync backs up to Cloudflare R2 daily using Restic
- **Postgres** - CloudNativePG streams WAL and a daily base backup to R2 (barman); each app's database is also dumped to the NAS every four hours by the `cnpg` component's CronJob
- **Cluster State** - Everything is in Git, Flux handles the rest
- **Secrets** - Stored in 1Password, pulled in via external-secrets

## Volsync Operations

Volsync handles backup/restore for PVCs. There are some assumptions baked in:

1. Kustomization, HelmRelease, PVC, and ReplicationSource all share the same name
2. ReplicationSource uses Restic
3. App is a Deployment or StatefulSet
4. Single PVC per app

### List Snapshots

```bash
task volsync:list APP=plex NS=media
```

### Create Manual Snapshot

If you need a backup right now instead of waiting for the daily schedule:

```bash
task volsync:snapshot APP=home-assistant NS=default
```

This waits up to 2 hours for the backup to complete.

### Restore from Backup

```bash
task volsync:restore APP=plex NS=media PREVIOUS=2
```

`PREVIOUS` is how many snapshots back to restore (0 = latest, 1 = one before latest, etc).

What happens under the hood:

1. Suspends Flux kustomization and helmrelease
2. Scales app to 0 replicas
3. Waits for pods to terminate
4. Creates a ReplicationDestination and restores data
5. Resumes Flux and reconciles
6. Waits for pods to be ready again

### Unlock Stuck Repos

If a backup job got interrupted, the Restic repo might be locked:

```bash
task volsync:unlock
```

### Suspend/Resume Volsync

For maintenance:

```bash
task volsync:state-suspend
task volsync:state-resume
```

### Verify Backups

Once a month, each app's `<app>-volsync-check` CronJob runs `restic check --read-data-subset=10%` on its R2 repo. A failed check raises the `KubeJobFailed` alert. To run a check by hand:

```bash
kubectl create job --from=cronjob/<app>-volsync-check <app>-volsync-check-manual -n <ns>
```

## Recovery Scenarios

### App Data Got Corrupted

1. List snapshots: `task volsync:list APP=<app> NS=<ns>`
2. Pick one and restore: `task volsync:restore APP=<app> NS=<ns> PREVIOUS=<n>`
3. Verify its working

### Node Died

With one node down, the cluster keeps working. etcd keeps quorum (2 of 3 members), Ceph keeps a copy of all data on each of the other 2 hosts, and CNPG promotes a replica if the primary was on that node.

1. Find the node that is down: `kubectl get nodes`.
2. Make sure that 2 etcd members are healthy:

   ```bash
   talosctl --nodes m0,m1,m2 etcd status
   ```

   If 2 nodes are down, etcd has no quorum. Go to [Complete Cluster Loss](#complete-cluster-loss).
3. Make sure that each CNPG cluster has a primary: `kubectl get cluster -n database`.
4. If the node only hangs, reboot it: `task talos:reboot-node NODE=<node>`.
5. If the Talos API does not answer, power-cycle the node.

If the node stays down, pods with a `ceph-block` volume on it stay stuck, because the volume cannot attach to another node.

> **WARNING:** Apply the out-of-service taint only when the node is powered off. If the node still runs, two nodes can write to the same volume and corrupt it.

6. Let the stuck pods move to other nodes:

   ```bash
   kubectl taint nodes <node> node.kubernetes.io/out-of-service=nodeshutdown:NoExecute
   ```

   Kubernetes deletes the pods on the node and detaches their volumes. Pods with an `openebs-hostpath` volume (CNPG instances, VolSync caches) cannot move, because their data is on that node.

#### Bring the Node Back

1. If the node needs a full reinstall and its Talos API answers, reset it: `task talos:reset-node NODE=<node>`.
2. If the Talos API does not answer, boot the node from the Talos ISO.
3. Apply the config: `task talos:apply-node NODE=<node>`. For a node in maintenance mode, the task adds `--insecure`.

   The node joins etcd again on its own. When a node with an empty etcd folder joins, Talos removes the old member with the same hostname.
4. If you applied the out-of-service taint, remove it:

   ```bash
   kubectl taint nodes <node> node.kubernetes.io/out-of-service=nodeshutdown:NoExecute-
   ```

5. Wait until the OSD of the node shows `up`: `kubectl rook-ceph ceph osd tree`.
6. Wait until Ceph shows `HEALTH_OK`: `kubectl rook-ceph ceph status`. While a node is down, Ceph has no other host for the third copy, so the data stays degraded until the recovery ends.
7. If the OSD does not come up because its disk is dead, follow [Removing a Dead OSD](storage-operations.md#removing-a-dead-osd).
8. Make sure that all 3 etcd members are healthy: `talosctl --nodes m0,m1,m2 etcd status`.

#### After a Reset or a New Node

A reset wipes the `EPHEMERAL` partition. It holds `/var/mnt/extra`, so all `openebs-hostpath` volumes on that node are gone, and their pods cannot start.

1. List the local volumes of the node:

   ```bash
   kubectl get pvc -A -o custom-columns='NS:.metadata.namespace,NAME:.metadata.name,NODE:.metadata.annotations.volume\.kubernetes\.io/selected-node,CLASS:.spec.storageClassName' \
     | awk '$3 == "<node>" && $4 == "openebs-hostpath"'
   ```

2. For each CNPG instance in the list, delete its PVC and pod: `kubectl delete -n database pvc/<instance> pod/<instance>`. CNPG then makes a new replica from the primary.
3. For each VolSync cache in the list (`volsync-*-cache`), delete the PVC: `kubectl delete -n <ns> pvc/<name>`. VolSync makes a new cache at its next run.
4. Leave the runner work volumes (`*-runner-*-work`). Each runner is temporary, and ARC makes a new one.

If a node never comes back, remove its old etcd member.

> **WARNING:** Do not remove the member of a node that can come back. Its etcd then cannot start until you reset the node.

1. List the members on a healthy node: `talosctl --nodes <healthy-node> etcd members`.
2. Remove the old member: `talosctl --nodes <healthy-node> etcd remove-member <member-id>`.

### Complete Cluster Loss

This is the nuclear option. Hopefully you never need this.

1. Provision hardware with Talos ISO (see [bootstrap](bootstrap.md))
2. Apply Talos config to all nodes:
   ```bash
   task talos:apply-node NODE=m0
   task talos:apply-node NODE=m1
   task talos:apply-node NODE=m2
   ```
3. Bootstrap:
   ```bash
   task bootstrap:talos
   task bootstrap:apps ROOK_DISK=<disk-model>
   ```
4. Flux restores everything from Git
5. Volsync restores PVC data from R2: every PVC created by the volsync component has a `ReplicationDestination` bootstrap, so this happens on its own
6. Postgres does **not** restore on its own. Before Flux creates the CNPG clusters, uncomment the `bootstrap.recovery` and `externalClusters` blocks in `kubernetes/apps/database/cloudnative-pg/cluster/cluster17.yaml` (and `immich.yaml`) and bump `serverName` (`postgres17-v1` → `postgres17-v2`), otherwise you get empty databases and the app restores fail their migrations

### Accidentally Deleted Something

Just force a Flux reconcile:

```bash
task kubernetes:reconcile
```

Flux will recreate whatever is missing from Git. After Flux recreates a deleted PVC, run `task volsync:restore APP=<app> NS=<ns> PREVIOUS=0` to replace its old bootstrap data with the newest backup.
