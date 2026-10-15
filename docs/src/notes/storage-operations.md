# Storage Operations

Notes on Rook-Ceph management and troubleshooting.

## Checking Cluster Health

The Rook toolbox pod is disabled; `ceph` runs through the `rook-ceph` kubectl plugin (`task workstation:krew` installs it).

```bash
kubectl rook-ceph ceph status
```

You want to see `HEALTH_OK`. If not, check whats wrong:

```bash
kubectl rook-ceph ceph health detail
```

Other useful commands:

```bash
# OSD tree
kubectl rook-ceph ceph osd tree

# Pool usage
kubectl rook-ceph ceph df

# OSD usage
kubectl rook-ceph ceph osd df
```

## Removing a Dead OSD

If a node died and you need to clean up the OSD (adapted from [Mirantis docs](https://docs.mirantis.com/container-cloud/latest/operations-guide/tshoot/tshoot-ceph/ceph-manual-osd-remove.html)):

```bash
# Check status
kubectl rook-ceph ceph -s

# Scale down the OSD (probably stuck in Pending if node is dead)
kubectl -n rook-ceph scale deploy rook-ceph-osd-<ID> --replicas 0

# Purge it
kubectl rook-ceph ceph osd purge <ID> --yes-i-really-mean-it

# Delete auth
kubectl rook-ceph ceph auth del osd.<ID>

# Remove node from CRUSH map if decomissioning
kubectl rook-ceph ceph osd crush remove <nodename>
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
   kubectl rook-ceph debug start rook-ceph-osd-<ID>
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
   kubectl rook-ceph ceph auth import -i osd.export
   ```

4. Clean up the debug pod: `kubectl rook-ceph debug stop rook-ceph-osd-<ID>`

The OSD should join and cluster should recover.

## Browsing PVC Contents

To poke around in a PVC:

```bash
task kubernetes:browse-pvc NS=media CLAIM=plex
```

This mounts it in an Alpine container for you to look around. Volume names match the app name (the VolSync component creates `<app>`); cache volumes are `<app>-cache`.

## Maintenance Mode

Before doing storage maintenance, prevent Ceph from rebalancing:

```bash
kubectl rook-ceph ceph osd set noout
```

Do your thing, then unset it:

```bash
kubectl rook-ceph ceph osd unset noout
```
