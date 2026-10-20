# AGENTS.md

Guidance for AI coding agents (Claude Code, Codex, etc.) working in this repository. `CLAUDE.md` imports this file, so keep all agent guidance here.

## Overview

Home Kubernetes cluster running on 3x MS-01 (i9-13900H, 96GB RAM) nodes (`m0`, `m1`, `m2`) with Talos Linux. Flux CD watches `kubernetes/` and reconciles all manifests. Infrastructure uses Rook-Ceph for block storage, Cilium for CNI, Envoy Gateway for ingress, Authelia + LLDAP for SSO, and 1Password/External-Secrets for secret management.

## Common Commands

All operations use [go-task](https://taskfile.dev). Run `task` to list all available tasks.

**Flux / Kubernetes:**
```sh
task kubernetes:reconcile          # Force Flux to pull latest changes
task kubernetes:hr:restart         # Restart all failed HelmReleases
task kubernetes:sync-secrets       # Force sync all ExternalSecrets
task kubernetes:cleanse-pods       # Delete pods in Failed/Pending/Completed state
task kubernetes:browse-pvc NS=default CLAIM=<name>   # Mount PVC in temp container
task kubernetes:node-shell NODE=<m0|m1|m2>           # Shell into a node
task kubernetes:nfs-pod NS=default                   # Start pod with NFS mounts
```

**VolSync (backups):**
```sh
task volsync:snapshot APP=<app> NS=default           # Trigger immediate backup
task volsync:restore APP=<app> NS=default PREVIOUS=1 # Restore from snapshot
task volsync:list APP=<app> NS=default               # List available snapshots
task volsync:unlock                                  # Unlock all restic repos
task volsync:state-suspend / volsync:state-resume    # Pause/resume all VolSync sources
```

**Talos:**
```sh
task talos:apply-node NODE=<m0|m1|m2>                # Render + apply machine config to a node
task talos:upgrade-node NODE=<m0|m1|m2> VERSION=<v> # Manually upgrade Talos (normally tuppr does this)
task talos:upgrade-k8s                               # Manually upgrade Kubernetes (normally tuppr does this)
task talos:kubeconfig                                # Regenerate kubeconfig
task talos:reboot-node NODE=<m0|m1|m2>               # Reboot a node
task talos:regen-certs                               # Regenerate Talos admin client certs (machine CA from 1Password)
task talos:reset-node NODE=<node> / talos:reset-cluster / talos:shutdown-cluster  # Destructive
```

**Terraform (Cloudflare):**
```sh
task terraform:cf:init             # Init the Cloudflare workspace
task terraform:cf:plan             # Show planned Cloudflare changes
task terraform:cf:apply            # Apply Cloudflare changes
```

**GitHub / Renovate PRs:**
```sh
task github:pr:list                # List open PRs
task github:pr:merge ID=<n>        # Merge a PR
task github:pr:merge:all SKIP_IDS= # Merge all open PRs (use with care)
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
│   ├── cluster/ks.yaml        # Flux entry point: loads meta, then every namespace under apps/
│   └── meta/
│       ├── crds/              # Gateway API and other CRDs
│       └── repositories/      # Helm and OCI repository definitions
├── apps/<namespace>/          # actions-runner-system, ai, cert-manager, database, default,
│   │                          # external-secrets, flux-system, kube-system, media,
│   │                          # networking, observability, openebs-system, rook-ceph,
│   │                          # system-upgrade, volsync-system, waitlist
│   ├── kustomization.yaml     # Lists each app's ks.yaml in this namespace
│   └── <app>/
│       ├── ks.yaml            # Flux Kustomization (dependsOn, components, postBuild vars)
│       └── app/
│           ├── kustomization.yaml   # Lists resources in this dir
│           ├── helmrelease.yaml     # HelmRelease referencing app-template or a chart
│           ├── externalsecret.yaml  # Pulls secrets from 1Password
│           └── resources/           # Config files mounted via configMapGenerator, if any
└── components/
    ├── common/                # Namespace, shared repos, cluster-secrets, alert configs
    ├── volsync/               # Adds VolSync (Restic→R2) backup + PVC to an app
    ├── cnpg/                  # Adds a CloudNative-PG database + backup CronJob + ExternalSecret
    └── dragonfly/             # Adds DragonflyDB (Redis-compat) cluster + NetworkPolicy
talos/
├── controlplane.yaml          # Base Talos machine config (rendered with minijinja-cli + op inject)
├── controlplane/<m0|m1|m2>.yaml  # Per-node config patches
└── schematic.yaml             # Talos image factory schematic
terraform/cloudflare/          # Cloudflare tunnel, rulesets, zone settings and the tunnel's 1Password item (DNS records come from external-dns)
bootstrap/                     # helmfile + resources for initial cluster setup
docs/                          # mdBook operations docs (published by the docs workflow)
```

## Architecture Patterns

### HelmReleases

Nearly all apps use the `app-template` chart (`oci://ghcr.io/bjw-s-labs/helm/app-template`) sourced via the `OCIRepository` defined in `components/common/repos/app-template/`. The `chartRef` in HelmReleases references `kind: OCIRepository, name: app-template`.

Install/upgrade failure handling is injected into every HelmRelease by a patch in `kubernetes/flux/cluster/ks.yaml` (a failed upgrade is rolled back to the last good release, and CRDs in a chart's `crds/` directory are replaced on every upgrade), so don't add `install`/`upgrade`/`uninstall` remediation blocks per app. Apps that run DB migrations on upgrade set `upgrade.strategy.name: RetryOnFailure` instead, since rolling the image back onto a migrated schema breaks them. Rollback only triggers if the pod fails its probes before the Helm timeout (5m), and app-template enables no probes by default, so give HTTP apps liveness/readiness/startup probes on a real health endpoint.

### Ingress / Routing

Apps expose themselves via Gateway API `HTTPRoute` under `route` in the app-template values. Hostnames follow `<app>.chestr.dev`. There are two gateways in the `networking` namespace, and choosing the right one is a security decision:

| Gateway | Reachable from | Auth in front |
|---|---|---|
| `envoy-internal` (**default**) | LAN / VPN only | Authelia ext-auth (`SecurityPolicy internal-secure`, fails closed) |
| `envoy-external` | The internet, via the Cloudflare tunnel | **None**: the app must do its own authentication |

- Use `envoy-internal` unless the app must be reachable from outside the home network.
- Only put an app on `envoy-external` if it has solid authentication of its own (e.g. OIDC through Authelia). Never expose admin UIs, shells or editors there.
- Authelia access rules live in `kubernetes/apps/default/authelia/app/resources/configuration.yaml`. The default is two-factor for the `admin` group and deny for everyone else. Apps with their own login are listed under `bypass`.
- Apps on `envoy-external` should carry a NetworkPolicy that only admits ingress from that gateway's Envoy pods (`gateway.envoyproxy.io/owning-gateway-name`) plus a CiliumNetworkPolicy admitting the `kube-apiserver` entity on the same port (cross-node gateway traffic is SNATed to a control-plane node). `default/radicale` and `waitlist` are the reference implementations; not every app has one yet.

### Secrets

All secrets come from 1Password via `ExternalSecret` resources referencing `ClusterSecretStore: onepassword`. Cluster-wide variables (e.g. `CLOUDFLARE_ACCOUNT_ID`, `CLOUDFLARE_TUNNEL_ID`) are injected into child Kustomizations via `postBuild.substituteFrom` pointing to the `cluster-secrets` Secret.

### Reusable Components

Add components to a `ks.yaml` under `spec.components`:
- `../../../../components/volsync`: adds a PVC + VolSync `ReplicationSource` to Cloudflare R2 (daily; 7 daily, 4 weekly, 3 monthly snapshots kept). Vars: `APP` (required), `VOLSYNC_CAPACITY` (default `5Gi`), and optionally `VOLSYNC_CACHE_CAPACITY`, `VOLSYNC_CACHE_STORAGECLASS`, `VOLSYNC_SCHEDULE`, `VOLSYNC_STORAGECLASS`, `VOLSYNC_SNAPSHOTCLASS`, `VOLSYNC_ACCESSMODES`, `VOLSYNC_CLAIM`, `APP_UID`/`APP_GID` (set these to the container's user when it is not 1000, or the restic mover cannot read root-owned files).
- `../../../../components/cnpg`: adds a database on a CloudNative-PG cluster + backup `CronJob` + `ExternalSecret`. Vars: `APP` (required), `CNPG_NAME` (optional, defaults to `postgres17`). Add credentials in 1Password first (see `kubernetes/components/cnpg/README.md`).
- `../../../../components/dragonfly`: adds a DragonflyDB instance with network policy and pod monitor. Vars: `APP` (required), `DRAGONFLY_REPLICAS` (default `1`; use `3` for anything that needs to survive a node reboot).

### Storage

- `ceph-block` (RWO): default for persistent app data backed by Rook-Ceph
- `openebs-hostpath`: used for VolSync cache volumes, CloudNative-PG clusters and ARC runner work volumes (local, faster)

### Talos Config

Configs are Jinja2 templates rendered via `minijinja-cli` and injected with secrets via `op inject`. Per-node patches in `talos/controlplane/<m0|m1|m2>.yaml` override the base `controlplane.yaml`. Changes to these files (including Renovate bumps to the `extraManifests` URLs) are **not** applied automatically: run `task talos:apply-node NODE=<node>` for each node (`MODE=auto` by default; Talos reboots only when the change needs it, and `talosctl apply-config --dry-run` shows what would change first).

### Upgrades (tuppr)

Talos and Kubernetes upgrades are driven by [tuppr](https://github.com/home-operations/tuppr) from `kubernetes/apps/system-upgrade/tuppr/upgrades/{talos,kubernetes}.yaml`, which Renovate bumps. tuppr upgrades one node at a time and waits for Ceph `HEALTH_OK` and idle VolSync before each node.
- Each Talos minor version only supports a range of Kubernetes versions. Upgrade Talos before bumping Kubernetes past that range.
- Apply any pending Talos config changes (above) before an upgrade. `upgrade-k8s` re-applies each node's `extraManifests`, and stale ones will fail it.
- If a run fails permanently, fix the cause and reset it: `kubectl annotate kubernetesupgrade kubernetes tuppr.home-operations.com/reset="$(date)"` (or `talosupgrade talos`).

### AI Stack (`ai` namespace)

- `litellm-operator` + `litellm`: an OpenAI-compatible LLM proxy. Models are declared as `LiteLLMModel` resources in `kubernetes/apps/ai/litellm/app/models/` and routed to hosted providers (OpenRouter), with no local GPU inference.
- `text-embeddings`: HuggingFace TEI serving `bge-small-en-v1.5` embeddings in-cluster.
- `memini`: persistent agent memory at `memini.chestr.dev`. It uses `text-embeddings` for vectors and `litellm` for chat. Its `/v1` and `/mcp` paths bypass Authelia because they are protected by memini's own API key.

### Observability

- Metrics: Prometheus from `kube-prometheus-stack` (ServiceMonitor/PodMonitor/PrometheusRule). Logs: Fluent Bit into VictoriaLogs. Log alerts are `VMRule` objects (`vmrule.yaml` beside the app) evaluated by a `VMAlert` in `observability/victoria-logs`; those kinds need the VictoriaMetrics operator CRDs.
- Public status page: Gatus at `status.chestr.dev`, fed by `gatus-sidecar` from every HTTPRoute; set `gatus.home-operations.com/enabled: "false"` on a route that should not be listed.

### Schema Headers

A `# yaml-language-server: $schema=` header is optional: it only helps editors, and Flux ignores it. For a CRD (Flux kinds included), use `https://kubernetes-schemas.pages.dev/<group>/<kind>_<version>.json`, with the kind in lower case and the version from the `apiVersion` line below the header. For an app-template HelmRelease, use `https://raw.githubusercontent.com/bjw-s-labs/helm-charts/main/charts/other/app-template/schemas/helmrelease-helm-v2.schema.json`, which also checks the chart values.

## Commit Conventions

Renovate enforces semantic commits; follow the same pattern manually:

| Scope | Usage |
|---|---|
| `feat(container)` / `fix(container)` | Container image updates (`feat` for minor, `fix` for patch and digest) |
| `feat(helm)` / `fix(helm)` | Helm chart updates |
| `chore(github-release)` | GitHub release updates |
| `ci(github-action)` | GitHub Actions updates |
| `fix(<app>)` / `feat(<app>)` | Changes to a specific app |
| `chore:` | General maintenance |

Major bumps and `0.x` minor bumps use the `!` suffix (e.g. `feat(container)!:`). The types and scopes come from the `home-operations/renovate-presets` preset.

## Renovate & CI

- Renovate automerges minor, patch and digest updates once they are 2 days old (3 days for GitHub Actions). Images and OCI charts outside Docker Hub get no minimum age and merge once the risk assessment passes. Majors, `0.x` minor bumps, core infrastructure (CNI, storage, Flux, Talos/Kubernetes, app-template, cert-manager, external-secrets) and apps with DB migrations always get a PR. Renovate itself (`renovatebot/renovate`) is the one exception: its majors also automerge. See `.renovaterc.json5`.
- Renovate runs in the cluster: `renovate-operator` (`renovate` namespace) starts a Renovate Job every hour for each repo listed in `discoveryFilters` of `renovatejob.yaml`, authenticated as the `mchesterbot` GitHub App. Its UI at `renovate.chestr.dev` shows runs and logs and can start a run now.
- `.github/workflows/ci.yaml` runs every PR check and reports one `CI Success` status. It runs Flux Local, the risk assessment, Flux Diff (a PR comment with the changed `HelmRelease` and `Kustomization` resources), image pre-pulls, actionlint and zizmor. Each job runs only when its files change.
