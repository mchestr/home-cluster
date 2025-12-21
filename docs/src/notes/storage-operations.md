# Storage Operations

Notes on Rook-Ceph management and troubleshooting.

## Checking Cluster Health

```bash
kubectl -n rook-ceph exec -it deploy/rook-ceph-tools -- ceph status
```

You want to see `HEALTH_OK`. If not, check whats wrong:

```bash
kubectl -n rook-ceph exec -it deploy/rook-ceph-tools -- ceph health detail
```

Other useful commands:

```bash
# OSD tree
kubectl -n rook-ceph exec -it deploy/rook-ceph-tools -- ceph osd tree

# Pool usage
kubectl -n rook-ceph exec -it deploy/rook-ceph-tools -- ceph df

# OSD usage
kubectl -n rook-ceph exec -it deploy/rook-ceph-tools -- ceph osd df
```

## Removing a Dead OSD

If a node died and you need to clean up the OSD (adapted from [Mirantis docs](https://docs.mirantis.com/container-cloud/latest/operations-guide/tshoot/tshoot-ceph/ceph-manual-osd-remove.html)):

```bash
# Check status
kubectl -n rook-ceph exec -it deploy/rook-ceph-tools -- ceph -s

# Scale down the OSD (probably stuck in Pending if node is dead)
kubectl -n rook-ceph scale deploy rook-ceph-osd-<ID> --replicas 0

# Purge it
kubectl -n rook-ceph exec -it deploy/rook-ceph-tools -- ceph osd purge <ID> --yes-i-really-mean-it

# Delete auth
kubectl -n rook-ceph exec -it deploy/rook-ceph-tools -- ceph auth del osd.<ID>

# Remove node from CRUSH map if decomissioning
kubectl -n rook-ceph exec -it deploy/rook-ceph-tools -- ceph osd crush remove <nodename>
```

## Cleaning a Disk

Ceph needs clean drives. If you've used the disk before, wipe it:

```bash
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: disk-clean-rook
  namespace: rook-ceph
spec:
  restartPolicy: Never
  nodeName: <nodename>
  volumes:
  - name: rook-data-dir
    hostPath:
      path: /var/lib/rook
  containers:
  - name: disk-clean
    image: busybox
    securityContext:
      privileged: true
    volumeMounts:
    - name: rook-data-dir
      mountPath: /node/rook-data
    command: ["/bin/sh", "-c", "rm -rf /node/rook-data/*"]
EOF
```

Wait for it then clean up:

```bash
kubectl -n rook-ceph delete pod disk-clean-rook
```

## OSD Won't Join After Moving Disk

Sometimes after moving a disk between nodes, the OSD fails with permission issues. Fix from [this GitHub issue](https://github.com/rook/rook/issues/4238#issuecomment-664627282):

1. Debug the OSD pod and grab the keyring:
   ```bash
   kubectl -n rook-ceph debug rook-ceph-osd-<ID>-<suffix>
   cat /var/lib/ceph/osd/ceph-<ID>/keyring
   ```

2. Create a file locally called `osd.export`:
   ```
   [osd.<ID>]
   key = <key from keyring>
   caps mon = "allow profile osd"
   caps mgr = "allow profile osd"
   caps osd = "allow *"
   ```

3. Import it:
   ```bash
   kubectl -n rook-ceph exec -it deploy/rook-ceph-tools -- ceph auth import -i osd.export
   ```

4. Clean up the debug pod

The OSD should join and cluster should recover.

## Browsing PVC Contents

To poke around in a PVC:

```bash
task kubernetes:browse-pvc NS=media CLAIM=plex-config
```

This mounts it in an Alpine container for you to look around.

## Maintenance Mode

Before doing storage maintenance, prevent Ceph from rebalancing:

```bash
kubectl -n rook-ceph exec -it deploy/rook-ceph-tools -- ceph osd set noout
```

Do your thing, then unset it:

```bash
kubectl -n rook-ceph exec -it deploy/rook-ceph-tools -- ceph osd unset noout
```
