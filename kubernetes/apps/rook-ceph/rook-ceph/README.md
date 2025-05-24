# Rook Ceph

A collection of useful procedures to troubleshoot and maintain the Rook Ceph storage system.

## Remove OSD

If the node is already dead, follow these steps to clean up the OSD. Procedure adapted from [Mirantis docs](https://docs.mirantis.com/container-cloud/latest/operations-guide/tshoot/tshoot-ceph/ceph-manual-osd-remove.html).

```bash
# Get status of Ceph cluster
kubectl -n rook-ceph ceph -s

# Scale OSD down (should be stuck in Pending if node is dead)
kubectl -n rook-ceph scale deploy rook-ceph-osd-<ID> --replicas 0

# Purge the OSD
kubectl -n rook-ceph ceph osd purge <ID> --yes-i-really-mean-it

# Delete authentication
kubectl -n rook-ceph ceph auth del osd.<ID>

# Remove dead node
kubectl -n rook-ceph ceph osd crush remove <nodename>
```

## Clean Rook Directory on Storage Device

Ceph requires a clean drive. If you have previously used the device, it's best to wipe it clean before adding it as an OSD.

Replace `<nodename>` with the name of the node you wish to wipe:

```bash
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: disk-clean-rook
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

## OSD Fails to Join Cluster

This issue can occur after moving a storage device from one node to another, especially if you've deleted the authentication as described above. If the OSD fails to join the cluster due to what appears to be a permission issue, follow these steps to import the credentials. Solution adapted from [this GitHub issue](https://github.com/rook/rook/issues/4238#issuecomment-664627282).

1. Start a debug pod for the OSD having issues:

```bash
kubectl -n rook-ceph debug stop rook-ceph-osd-<ID>
```

2. Exec into the debug pod and retrieve the keyring:

```bash
cat /var/lib/ceph/osd/ceph-<ID>/keyring
```

3. Create a file locally named `osd.export` with the contents of the keyring plus permissions:

```plaintext
[osd.<ID>]
key = <key>
caps mon = "allow profile osd"
caps mgr = "allow profile osd"
caps osd = "allow *"
```

4. Import it into Ceph:

```bash
kubectl -n rook-ceph ceph auth import -i osd.export
```

5. Clean up the debug pod:

```bash
kubectl -n rook-ceph debug stop rook-ceph-osd-<ID>
```

If successful, the OSD should join and the cluster should recover.
