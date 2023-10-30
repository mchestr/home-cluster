### Rook Ceph

Collection of useful things I have done in the past to fix stuff...

### Remove OSD

If the Node is already dead, then we gotta do some stuff to clean it up... Taken from [here](https://docs.mirantis.com/container-cloud/latest/operations-guide/tshoot/tshoot-ceph/ceph-manual-osd-remove.html)

```
# Get Status Of Ceph Cluster
kubelet rook-ceph ceph -s

# Scale OSD Down (should be stuck in Pending if node is dead)
kubectl -n rook-ceph scale deploy rook-ceph-osd-<ID> --replicas 0

# Purge it
kubectl rook-ceph ceph osd purge <ID> --yes-i-really-mean-it

# Delete Auth
kubectl ceph auth del osd.<ID>

# Remove dead node
kubectl rook-ceph ceph osd crush remove <nodename>
```

### Clean Rook Directory on Storage Device

Ceph likes a nice clean drive, and if you have previously used the device it might have left over stuff, best to wipe it clean before adding as an OSD.

Replace `<nodename>` with the name of the node you wish to wipe.

```
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

### OSD Fails to Join Cluster

I ran into this after moving a storage device from 1 node to the other, probably also because I deleted the auth above, anyway, if the OSD fails to join the cluster due to what appears to be a permission issue, the fix is relatively straight forward and we need to import the credentials. Taken from [here](https://github.com/rook/rook/issues/4238#issuecomment-664627282)


Start a debug pod for the OSD having issues

```
kubectl rook-ceph debug stop rook-ceph-osd-<ID>
```

Exec into the debug pod

```
cat /var/lib/ceph/osd/ceph-<ID>/keyring
```

Make a file locally `osd.export` where kubectl is and put in the contents of the keyring + permissions

```
[osd.<ID>]
key = <key>
caps mon = "allow profile osd"
caps mgr = "allow profile osd"
caps osd = "allow *"
```

Import it into Ceph

```
kubectl rook-ceph ceph auth import -i osd.export
```

Clean up the debug pod.

```
kubectl rook-ceph debug stop rook-ceph-osd-<ID>
```

With any luck, the OSD should join and cluster should recover.
