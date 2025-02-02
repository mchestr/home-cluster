# Cluster Bootstrap

The process should be mostly automated via the `task bootstrap:apps` command. If all goes well
the cluster should come up based on the last available snapshot taken by volsync, which is run daily.


## Rook Ceph

In the process of bootstrapping, or general restarting of a cluster rook ceph will have a bad time
if the disks are not cleaned and/or there is any left over rook configuration files. It is important
these be cleaned in order for rook and ceph to create successfully.

This process hasn't been fully tested, but should be automated as part of the general bootstrap
process above, but in case of fire try following remedies:

1. run the `wipe-rook` in [helmfile.yaml](https://github.com/mchestr/home-cluster/blob/main/kubernetes/bootstrap/apps/helmfile.yaml)

if that fails:

1. modify (if applicable) the parameters in [clea-ceph.sh](https://github.com/mchestr/home-cluster/blob/main/hack/clean-ceph.sh)
  1. This will delete `/var/lib/rook`
  1. and zero out `/dev/nvme01` on the nodes used for ceph
