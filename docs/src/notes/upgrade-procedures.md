# Upgrade Procedures

How to upgrade Talos, Kubernetes, and everything else.

## Before You Upgrade

Always a good idea to check things are healthy first:

```bash
kubectl get nodes
kubectl -n rook-ceph exec -it deploy/rook-ceph-tools -- ceph status
```

And maybe take a manual backup of anything critical:

```bash
task volsync:snapshot APP=<app> NS=<ns>
```

## Talos Upgrades

### Single Node

```bash
task talos:upgrade-node NODE=m0 VERSION=v1.9.0
```

This downloads the Talos version from the factory, applies it with secure boot, and reboots. Times out after 10 minutes.

### Rolling Upgrade

For the whole cluster, just do them one at a time and wait for each to come back:

```bash
task talos:upgrade-node NODE=m0 VERSION=v1.9.0
# wait for it to rejoin
task talos:upgrade-node NODE=m1 VERSION=v1.9.0
# wait
task talos:upgrade-node NODE=m2 VERSION=v1.9.0
```

Between each, verify the node is Ready and Ceph is healthy:

```bash
kubectl get nodes
kubectl -n rook-ceph exec -it deploy/rook-ceph-tools -- ceph status
```

## Kubernetes Upgrades

```bash
task talos:upgrade-k8s
```

This upgrades Kubernetes across all nodes. The version comes from `kubernetes/apps/system-upgrade/tuppr/upgrades/kubernetes.yaml`.

## Flux and Helm Charts

Renovate handles this automatically - it creates PRs when updates are available. Just review and merge them.

To force a reconcile after merging:

```bash
task kubernetes:reconcile
```

### Merge Renovate PRs

```bash
# List open PRs
task github:pr:list

# Merge one
task github:pr:merge ID=123

# Merge all of them
task github:pr:merge:all
```

## ARC Upgrade

Actions Runner Controller needs a special upgrade process because of CRD stuff:

```bash
task kubernetes:upgrade-arc
```

This uninstalls the runner and controller, waits a bit, then reconciles them back via Flux.

## Rollback

### Talos

Talos keeps the previous install around. Reboot and pick the old one from the boot menu:

```bash
task talos:reboot-node NODE=<node> MODE=powercycle
```

### Flux/Helm

Just revert the commit and push:

```bash
git revert <commit>
git push
task kubernetes:reconcile
```

## If Things Go Wrong

### Node Stuck During Upgrade

Check whats happening:

```bash
talosctl -n <node> dmesg | tail -100
```

Force a reboot if needed:

```bash
task talos:reboot-node NODE=<node> MODE=powercycle
```

### Can't Connect After Upgrade

Regenerate kubeconfig:

```bash
task talos:kubeconfig
```

### Helm Releases Failing

Restart failed releases:

```bash
task kubernetes:hr:restart
```
