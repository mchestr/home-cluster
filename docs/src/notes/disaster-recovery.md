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

If recoverable, just reboot it:

```bash
task talos:reboot-node NODE=<node>
```

If it needs a full reinstall:

```bash
task talos:reset-node NODE=<node>
task talos:apply-node NODE=<node>
```

Ceph will rebalance automatically. Check health with:

```bash
kubectl rook-ceph ceph status
```

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

Flux will recreate whatever is missing from Git.
