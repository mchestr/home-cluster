## Talos

[Talos](https://www.talos.dev/) is a Kubernetes Operating System. The infrastructure is managed via [talhelper](https://github.com/budimanjojo/talhelper) which helps you generate the Talos `machineconfig`. Talos also has a CLI tool [talosctl](https://www.talos.dev/v1.5/learn-more/talosctl/) for interfacing with your nodes, which is required to do anything with Talos.

### Talhelper

Talhelper uses the config in [talconfig.yaml](./talconfig.yaml), and sops encrypted [talenv.sops.yaml](./talenv.sops.yaml) and [talsecret.sops.yaml](./talsecret.sops.yaml) to generate the [machineconfig](https://www.talos.dev/v1.5/reference/configuration/) required to configure all the nodes. This allows me to define all my infrastructure as code and easily apply it. Checkout talhelper, or browse the [talconfig.yaml](./talconfig.yaml) to see how that is done.

### Useful Tasks

Using [tasks](https://github.com/go-task/task) I have defined some useful Talos commands I use to manage my cluster.

#### Install/Upgrade Talos CLI tools

- [task talos:init](../.taskfiles/TalosTasks.yml)


#### Install CNI

This task is needed to bootstrap the CNI/Cert Approver initially on the cluster, or fix issues if the HelmRelease is broken when managed via Flux.

- [task talos:install:cni](../.taskfiles/TalosTasks.yml)

Afterwards Flux should take over and do any future upgrades as it is part of my [Flux Kustomizations](../kubernetes/apps/kube-system/cilium/ks.yaml)


#### Upgrade Talos

This task will rollout a Talos OS upgrade on each node, and wait for rook-ceph/postgres clusters to become healthy before proceeding on the next node.

- [task talos:upgrade:all](../.taskfiles/TalosTasks.yml)

#### Upgrade Kubernetes

This task will rollout a Kubernetes upgrade.

- [task talos:upgrade:k8s](../.taskfiles/TalosTasks.yml)


### Troubleshooting

#### Get Current Machine Config

Sometimes you may be trying to diff what `talhelper` generates, and what is currently applied. To get the current machineconfig run the following.

```
talosctl -n <ip> get machineconfig -o yaml
```

#### etcd Unhealthy due to Dead Control Plane

Trying to add another control plane node to replace a dead one was having difficulty joining the etcd cluster. Here is how I fixed it.

Get status of etcd

```
talosctl -n <nodeip> services
```

If it is stuck pending, check the status of etcd.

```
talosctl -n <nodeip> etcd status
talosctl -n <nodeip> etcd members
```

If it is unhealthy due to the dead node, we can remove it so etcd recovers quorum and becomes healthy.

```
talosctl -n <nodeip> etcd remove-member <id>
```

If all goes well, the new control plane should join successfully and etcd will be running. Check etcd status to ensure state is `Running`.

```
talosctl -n <nodeip> services
```
