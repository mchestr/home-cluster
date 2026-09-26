# Upgrade Procedures

How to upgrade Talos, Kubernetes, and everything else.

## Before You Upgrade

Always a good idea to check things are healthy first. There's no Ceph toolbox pod, so run `ceph` through the operator:

```bash
kubectl get nodes
kubectl -n rook-ceph exec deploy/rook-ceph-operator -- ceph -c /var/lib/rook/rook-ceph/rook-ceph.config status
```

And maybe take a manual backup of anything critical:

```bash
task volsync:snapshot APP=<app> NS=<ns>
```

## Talos & Kubernetes (tuppr)

Talos and Kubernetes upgrades are automated by [tuppr](https://github.com/home-operations/tuppr). The target versions live in:

- `kubernetes/apps/system-upgrade/tuppr/upgrades/talos.yaml`
- `kubernetes/apps/system-upgrade/tuppr/upgrades/kubernetes.yaml`

Renovate opens PRs to bump them. Merging the PR is the upgrade: tuppr rolls through the nodes one at a time and, before each node, waits for:

- Ceph to be `HEALTH_OK`
- no VolSync backups to be in progress

Talos upgrades power-cycle each node, so expect Ceph to go briefly degraded while a node is down. Watch progress with:

```bash
kubectl get talosupgrade,kubernetesupgrade
kubectl -n system-upgrade get jobs,pods
```

### Things to check first

- **Version compatibility.** Each Talos minor version only supports a range of Kubernetes versions (e.g. Talos 1.13 supports Kubernetes 1.31–1.36; 1.37 needs Talos 1.14). Upgrade Talos first, then Kubernetes. The ranges are in Talos's [support matrix](https://docs.siderolabs.com/talos/latest/getting-started/support-matrix).
- **Pending Talos config changes.** Changes to `talos/controlplane.yaml` (including Renovate bumps to the `extraManifests` URLs) are not applied automatically. Apply them before upgrading, because `upgrade-k8s` re-applies each node's own `extraManifests` and fails on stale ones:

  ```bash
  task talos:apply-node NODE=m0   # repeat for m1, m2; dry-run first to see if a reboot is needed
  ```

### Retrying a failed upgrade

When tuppr runs out of retries it marks the upgrade `Failed` and stops. Fix the cause, then reset it:

```bash
kubectl annotate kubernetesupgrade kubernetes tuppr.home-operations.com/reset="$(date)"
kubectl annotate talosupgrade talos tuppr.home-operations.com/reset="$(date)"
```

### Manual upgrades

If tuppr isn't an option, the old manual tasks still work. Do one node at a time and wait for it to rejoin, and for Ceph to be healthy, before moving on:

```bash
task talos:upgrade-node NODE=m0 VERSION=v1.13.10
task talos:upgrade-k8s   # version comes from tuppr/upgrades/kubernetes.yaml
```

## Flux and Helm Charts

Renovate automerges minor, patch and digest updates once they're 2 days old. Majors, `0.x` minor bumps, core infrastructure (CNI, storage, Flux, Talos/Kubernetes, app-template, cert-manager, external-secrets) and apps with database migrations still get a PR to review. The rules are in `.github/renovate/autoMerge.json5`.

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

A failed Helm upgrade is rolled back automatically to the last good release (configured centrally in `kubernetes/flux/cluster/ks.yaml`). Rollback only triggers if the pod fails its probes before the Helm timeout, so apps need real health probes.

Apps that run database migrations are the exception. They use `RetryOnFailure` instead, because rolling the image back onto a migrated schema breaks them. If one of those fails, fix forward rather than reverting.

Otherwise, just revert the commit and push:

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

If an upgrade is stuck waiting on pods that will never become ready, scaling the app's deployments to 0 lets Flux finish the Helm upgrade. Force another reconcile afterwards if the replicas stay at 0:

```bash
flux reconcile hr -n <ns> <app> --force
```
