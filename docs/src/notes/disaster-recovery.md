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

### Database Recovery

Each CNPG Cluster (`postgres17`, `immich`) sends WAL and a daily base backup to R2, in `s3://cloudnative-pg/<serverName>/`. The recovery depends on these facts:

- CNPG reads `bootstrap` only when it creates the first instance of a new Cluster. Thus a recovery always needs a new Cluster.
- CNPG accepts one bootstrap method only. In `immich.yaml`, comment out `initdb` when you uncomment `recovery`.
- Before a recovery starts, CNPG checks that the backup `serverName` is empty. If it is not empty, the Cluster stays in `Setting up primary` with `Expected empty archive`.
- Without `recoveryTarget`, CNPG restores the newest base backup and replays all WAL in R2. The recovery does not get WAL that PostgreSQL did not send yet (`archive_timeout` is `5min`).
- The CNPG 1.30 operator warns that CNPG 1.31.0 removes `barmanObjectStore`. When the Clusters move to the Barman Cloud Plugin, change these recovery blocks too.
- The `cnpg` component also writes a pg_dump of each app database to the NAS every 4 hours. Use it only if R2 has no usable backup.

WARNING: Do not set `cnpg.io/skipEmptyWalArchiveCheck`. Two Clusters that write to one `serverName` can destroy its backups.

#### Recover a Cluster

In these steps, `<cluster>` is `postgres17` or `immich`. `<file>` is `cluster17.yaml` or `immich.yaml` in `kubernetes/apps/database/cloudnative-pg/cluster/`. After [Complete Cluster Loss](#complete-cluster-loss), steps 5 to 12 come before `task bootstrap:apps`, and steps 16 to 20 come after it.

1. If the Cluster still runs, do a [test recovery](#test-a-recovery-each-quarter) first.
2. Find the first point of recoverability and the last archived WAL:
   ```bash
   kubectl cnpg status <cluster> -n database
   ```
3. Suspend the Flux Kustomization of the Clusters:
   ```bash
   flux suspend kustomization cloudnative-pg-cluster -n database
   ```
4. If the Cluster still runs, send the current WAL file to R2:
   ```bash
   kubectl cnpg psql <cluster> -n database -- -c 'SELECT pg_switch_wal();'
   ```
5. In `<file>`, find the value of `serverName: &currentCluster`, for example `postgres17-v1`. This `serverName` has the newest backups.
6. Set `source: &previousCluster` to that value.
7. Uncomment the `recovery` lines and the `externalClusters` block, if they are commented.
8. In `immich.yaml` only, comment out `initdb` and its `postInitSQL` lines.
9. Increase the version in `serverName: &currentCluster` by one, for example `postgres17-v1` to `postgres17-v2`.
10. Optional: to stop before a bad change, add a `recoveryTarget` under `recovery`:
    ```yaml
    recovery:
      source: &previousCluster postgres17-v1
      recoveryTarget:
        targetTime: "2026-10-18T09:00:00Z" # UTC, before the bad change
    ```
11. Make sure that the change builds:
    ```bash
    kustomize build kubernetes/apps/database/cloudnative-pg/cluster
    ```
12. Commit and push the change.
13. WARNING: This step deletes the Cluster PVCs and all data on them.

    Delete the Cluster:
    ```bash
    kubectl delete cluster <cluster> -n database
    ```
14. Make Flux get the new commit:
    ```bash
    task kubernetes:reconcile
    ```
15. WARNING: Resume Flux only after you delete the Cluster. Flux must create a new Cluster, not change the running one.

    Resume the Flux Kustomization:
    ```bash
    flux resume kustomization cloudnative-pg-cluster -n database
    ```
16. Monitor the recovery. The log shows `redo done` when PostgreSQL completes the WAL replay:
    ```bash
    kubectl logs -n database job/<cluster>-1-full-recovery -f
    ```
17. Wait for `Cluster in healthy state`. Until then, the Kustomization can show a health check timeout:
    ```bash
    kubectl get cluster <cluster> -n database -w
    ```
18. Check the databases:
    ```bash
    kubectl cnpg psql <cluster> -n database -- -c '\l+'
    ```
19. Make a base backup in the new `serverName`. Until it completes, the new `serverName` has no base backup:
    ```bash
    kubectl cnpg backup <cluster> -n database
    ```
20. Keep the recovery block, without `initdb`, in `<file>`. The next recovery starts at step 5.

If the log shows `Expected empty archive`, the new `serverName` already has data in R2:

1. Do step 3.
2. Increase the version in `serverName: &currentCluster` again.
3. Do steps 11 to 15.

CNPG applies `retentionPolicy` only to the current `serverName`. The old `serverName` stays in R2 until you delete it.

#### Test a Recovery Each Quarter

This test recovers the newest backups of `postgres17` and `immich` into a scratch Cluster each quarter. The scratch Cluster has no `backup` section, so it only reads from R2. These steps use `postgres17`. The immich test uses the same steps with `immich`.

1. Make the scratch Cluster manifest from the live Cluster:
   ```bash
   kubectl get cluster postgres17 -n database -o yaml | yq '{
     "apiVersion": .apiVersion,
     "kind": .kind,
     "metadata": {"name": .metadata.name + "-restore-test", "namespace": .metadata.namespace},
     "spec": {
       "instances": 1,
       "imageName": .spec.imageName,
       "storage": .spec.storage,
       "postgresql": {
         "shared_preload_libraries": (.spec.postgresql.shared_preload_libraries // []),
         "parameters": (.spec.postgresql.parameters | with_entries(select(.key == "max_connections" or .key == "max_locks_per_transaction")))
       },
       "bootstrap": {"recovery": {"source": "source"}},
       "externalClusters": [{"name": "source", "barmanObjectStore": .spec.backup.barmanObjectStore}]
     }
   }' > /tmp/restore-test.yaml
   ```
2. Make sure that the manifest has no `backup` section. This command must print `false`:
   ```bash
   yq '.spec | has("backup")' /tmp/restore-test.yaml
   ```
3. WARNING: Do not add a `backup` section to the scratch Cluster. It would write to R2 next to the live backups.

   Create the scratch Cluster:
   ```bash
   kubectl apply -f /tmp/restore-test.yaml
   ```
4. Monitor the recovery. The `last completed transaction` line shows the time of the newest recovered change:
   ```bash
   kubectl logs -n database job/postgres17-restore-test-1-full-recovery -f
   ```
5. Wait for `Cluster in healthy state`:
   ```bash
   kubectl get cluster postgres17-restore-test -n database -w
   ```
6. Compare the databases with the live Cluster. The two lists must show the same databases:
   ```bash
   kubectl cnpg psql postgres17-restore-test -n database -- -c '\l+'
   kubectl cnpg psql postgres17 -n database -- -c '\l+'
   ```
7. For immich only, make sure that the `immich` database has the `vchord` extension:
   ```bash
   kubectl cnpg psql immich-restore-test -n database -- -d immich -c '\dx'
   ```
8. Delete the scratch Cluster. Kubernetes deletes its PVC with it:
   ```bash
   kubectl delete cluster postgres17-restore-test -n database
   ```

### Accidentally Deleted Something

Just force a Flux reconcile:

```bash
task kubernetes:reconcile
```

Flux will recreate whatever is missing from Git. After Flux recreates a deleted PVC, run `task volsync:restore APP=<app> NS=<ns> PREVIOUS=0` to replace its old bootstrap data with the newest backup.
