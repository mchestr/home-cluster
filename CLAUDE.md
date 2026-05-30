# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Home Kubernetes cluster running on 3x MS-01 (i9-13900H, 96GB RAM) nodes with Talos Linux. Flux CD watches `kubernetes/` and reconciles all manifests. Infrastructure uses Rook-Ceph for block storage, Cilium for CNI, Envoy Gateway for ingress, and 1Password/External-Secrets for secret management.

## Common Commands

All operations use [go-task](https://taskfile.dev). Run `task` to list all available tasks.

**Flux / Kubernetes:**
```sh
task kubernetes:reconcile          # Force Flux to pull latest changes
task kubernetes:hr:restart         # Restart all failed HelmReleases
task kubernetes:sync-secrets       # Force sync all ExternalSecrets
task kubernetes:cleanse-pods       # Delete pods in Failed/Pending/Completed state
task kubernetes:browse-pvc NS=default CLAIM=<name>   # Mount PVC in temp container
task kubernetes:node-shell NODE=<ip>                 # Shell into a Talos node
task kubernetes:nfs-pod NS=default                   # Start pod with NFS mounts
```

**VolSync (backups):**
```sh
task volsync:snapshot APP=<app> NS=default           # Trigger immediate backup
task volsync:restore APP=<app> NS=default PREVIOUS=1 # Restore from snapshot
task volsync:list APP=<app> NS=default               # List available snapshots
task volsync:unlock                                  # Unlock all restic repos
```

**Talos:**
```sh
task talos:apply-node NODE=<ip>                      # Apply config to a node
task talos:upgrade-node NODE=<ip> VERSION=<ver>      # Upgrade Talos on a node
task talos:upgrade-k8s                               # Upgrade Kubernetes cluster-wide
task talos:kubeconfig                                # Regenerate kubeconfig
task talos:reboot-node NODE=<ip>                     # Reboot a node
```

**Terraform (Cloudflare):**
```sh
task terraform:cf:plan             # Show planned Cloudflare changes
task terraform:cf:apply            # Apply Cloudflare changes
```

**Bootstrap (initial cluster only):**
```sh
task bootstrap:talos               # Bootstrap Talos cluster
task bootstrap:apps ROOK_DISK=<model>  # Deploy core apps
```

## Repository Structure

```
kubernetes/
├── flux/
│   ├── cluster/ks.yaml        # Flux entry point — loads meta then all apps
│   └── meta/
│       ├── crds/              # Gateway API and other CRDs
│       └── repositories/      # Helm and OCI repository definitions
├── apps/<namespace>/<app>/
│   ├── ks.yaml                # Flux Kustomization (depends, components, postBuild vars)
│   └── app/
│       ├── kustomization.yaml # Lists resources in this dir
│       ├── helmrelease.yaml   # HelmRelease referencing app-template or a chart
│       └── externalsecret.yaml  # Pulls secrets from 1Password
└── components/
    ├── common/                # Namespace, shared repos, cluster-secrets, alert configs
    ├── volsync/               # Adds VolSync (Restic→R2) backup + PVC to an app
    ├── cnpg/                  # Adds CloudNative-PG database + ExternalSecret
    └── dragonfly/             # Adds DragonflyDB (Redis-compat) cluster + NetworkPolicy
talos/
├── controlplane.yaml          # Base Talos machine config (rendered with minijinja-cli + op inject)
├── controlplane/<node>.yaml   # Per-node config patches
└── schematic.yaml             # Talos image factory schematic
terraform/cloudflare/          # DNS records, Cloudflare tunnels, access policies
bootstrap/                     # helmfile + resources for initial cluster setup
```

## Architecture Patterns

### Adding a New App

1. Create `kubernetes/apps/<namespace>/<appname>/ks.yaml` — a `Kustomization` pointing to `./app`, listing `dependsOn`, `components`, and `postBuild.substitute` vars.
2. Create `kubernetes/apps/<namespace>/<appname>/app/` with `kustomization.yaml`, `helmrelease.yaml`, and optionally `externalsecret.yaml`.
3. Add the new app directory to the namespace's parent `kustomization.yaml` resources list.

### HelmReleases

Nearly all apps use the `app-template` chart (`oci://ghcr.io/bjw-s-labs/helm/app-template`) sourced via the `OCIRepository` defined in `components/common/repos/app-template/`. The `chartRef` in HelmReleases references `kind: OCIRepository, name: app-template`.

### Ingress / Routing

Apps expose themselves via Gateway API `HTTPRoute` (or similar) under `spec.route` in the app-template values. The external gateway is `envoy-external` in namespace `networking`. Hostnames follow the pattern `<appname>.chestr.dev`. NetworkPolicies on each app should allow ingress from the Envoy pods in `networking`.

### Secrets

All secrets come from 1Password via `ExternalSecret` resources referencing `ClusterSecretStore: onepassword`. Cluster-wide variables (e.g. `CLOUDFLARE_ACCOUNT_ID`, `CLOUDFLARE_TUNNEL_ID`) are injected into child Kustomizations via `postBuild.substituteFrom` pointing to the `cluster-secrets` Secret.

### Reusable Components

Add components to a `ks.yaml` under `spec.components`:
- `../../../../components/volsync` — adds a PVC + VolSync `ReplicationSource` to Cloudflare R2. Requires `postBuild.substitute` vars: `APP`, `VOLSYNC_CAPACITY`, and optionally `VOLSYNC_CACHE_CAPACITY`.
- `../../../../components/cnpg` — adds a CloudNative-PG `Cluster` + backup `CronJob` + `ExternalSecret`. Requires `CNPG_NAME` var. Add credentials in 1Password first (see `kubernetes/components/cnpg/README.md`).
- `../../../../components/dragonfly` — adds a DragonflyDB instance with network policy and pod monitor.

### Storage

- `ceph-block` (RWO) — default for persistent app data backed by Rook-Ceph
- `openebs-hostpath` — used for VolSync cache volumes (local, faster)

### Talos Config

Configs are Jinja2 templates rendered via `minijinja-cli` and injected with secrets via `op inject`. Per-node patches in `talos/controlplane/<node>.yaml` override the base `controlplane.yaml`.

## Commit Conventions

Renovate enforces semantic commits; follow the same pattern manually:

| Scope | Usage |
|---|---|
| `feat(container)` / `fix(container)` / `chore(container)` | Container image updates |
| `feat(helm)` / `fix(helm)` | Helm chart updates |
| `feat(github-release)` / `fix(github-release)` | GitHub release updates |
| `fix(networking)` | Networking/CRD fixes |
| `chore:` | General maintenance |

Major bumps use `!` suffix (e.g. `feat(container)!:`).

## CI

The `flux-diff` GitHub Actions workflow posts a diff of changed `HelmRelease` and `Kustomization` resources as a PR comment whenever `kubernetes/apps/**` or `kubernetes/flux/**` changes.
