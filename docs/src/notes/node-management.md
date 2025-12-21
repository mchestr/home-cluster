# Node Management

How to manage Talos nodes - config, maintenance, and recovery.

## Current Setup

| Node | Role | Hardware |
|------|------|----------|
| m0 | Control Plane | MS-01 i9-13900H, 96GB RAM, 1TB OS + 2TB Data |
| m1 | Control Plane | MS-01 i9-13900H, 96GB RAM, 1TB OS + 2TB Data |
| m2 | Control Plane | MS-01 i9-13900H, 96GB RAM, 1TB OS + 2TB Data |

All three are control plane nodes with workloads scheduled on them.

## Applying Config

```bash
task talos:apply-node NODE=<node>
```

| Option | Default | What it does |
|--------|---------|--------------|
| `MODE` | `auto` | Apply mode - `auto` (Talos decides), `reboot` (force reboot), `staged` (apply on next reboot) |

Config files are in:

```
talos/
├── controlplane.yaml          # Base config
├── controlplane/
│   ├── m0.yaml               # Node-specific patches
│   ├── m1.yaml
│   └── m2.yaml
└── schematic.yaml             # Factory schematic for Secure Boot
```

## Rebooting

```bash
task talos:reboot-node NODE=<node>
```

Add `MODE=powercycle` for a hard reboot if needed.

## Shutting Down the Cluster

```bash
task talos:shutdown-cluster
```

To bring it back up, just power on the machines. Talos boots and rejoins automatically.

## Regenerating Kubeconfig

If kubeconfig expires or gets messed up:

```bash
task talos:kubeconfig
```

## Maintenance Procedure

Before doing maintenance on a node:

1. Check things are healthy:
   ```bash
   kubectl get nodes
   kubectl -n rook-ceph exec -it deploy/rook-ceph-tools -- ceph status
   ```

2. Tell Ceph not to rebalance:
   ```bash
   kubectl -n rook-ceph exec -it deploy/rook-ceph-tools -- ceph osd set noout
   ```

3. Cordon and drain:
   ```bash
   kubectl cordon <node>
   kubectl drain <node> --ignore-daemonsets --delete-emptydir-data
   ```

4. Do your maintenance

5. Uncordon:
   ```bash
   kubectl uncordon <node>
   ```

6. Unset noout:
   ```bash
   kubectl -n rook-ceph exec -it deploy/rook-ceph-tools -- ceph osd unset noout
   ```

## Resetting a Node

If you need to wipe a node and start fresh:

```bash
task talos:reset-node NODE=<node>
```

This destroys everything on the node.

## Resetting the Whole Cluster

Nuclear option:

```bash
task talos:reset-cluster
```

Make sure you have backups before doing this.

## Adding a New Node

1. Install Talos ISO, set up Secure Boot (see [bootstrap](bootstrap.md))
2. Create a node config in `talos/controlplane/<new-node>.yaml`
3. Apply config: `task talos:apply-node NODE=<new-node>`
4. Watch it join: `kubectl get nodes -w`
5. If it has storage, Rook will discover and provision OSDs

## Removing a Node

1. Drain workloads: `kubectl drain <node> --ignore-daemonsets --delete-emptydir-data`
2. If it has Ceph OSDs, remove them first (see [storage-operations](storage-operations.md))
3. Delete from cluster: `kubectl delete node <node>`
4. Optionally reset: `task talos:reset-node NODE=<node>`

## Node Shell Access

For low-level debugging:

```bash
task kubernetes:node-shell NODE=<node>
```

This gives you a privileged shell on the node.
