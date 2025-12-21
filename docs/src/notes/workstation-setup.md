# Workstation Setup

What you need to manage the cluster from your machine.

## Quick Setup

```bash
# Install Homebrew packages
task workstation:brew

# Install kubectl plugins
task workstation:krew
```

## Required Tools

Everything gets installed via Homebrew.

### Core

| Tool | Purpose |
|------|---------|
| `kubernetes-cli` | kubectl |
| `talosctl` | Talos node management |
| `flux` | Flux CLI |
| `helm` | Helm |
| `helmfile` | Declarative Helm |
| `kustomize` | Kustomize |

### Development

| Tool | Purpose |
|------|---------|
| `go-task` | Task runner |
| `jq` | JSON wrangling |
| `yq` | YAML wrangling |
| `age` | Encryption |
| `sops` | Secret operations |

### Cluster Management

| Tool | Purpose |
|------|---------|
| `k9s` | Terminal UI for Kubernetes |
| `kubecolor` | Colorized kubectl |
| `stern` | Multi-pod log tailing |
| `viddy` | Modern watch command |

### Infrastructure

| Tool | Purpose |
|------|---------|
| `cloudflared` | Cloudflare tunnel |
| `gh` | GitHub CLI |
| `talhelper` | Talos config helper |
| `minijinja-cli` | Template rendering |

### Secrets

| Tool | Purpose |
|------|---------|
| `1password` | 1Password app |
| `1password-cli` | 1Password CLI |

## kubectl Plugins

Installed via Krew:

| Plugin | Purpose |
|--------|---------|
| `browse-pvc` | Browse PVC contents |
| `node-shell` | Shell into nodes |
| `rook-ceph` | Rook-Ceph commands |
| `view-secret` | Decode secrets |
| `cert-manager` | Cert-manager commands |
| `cnpg` | CloudNativePG commands |

## Configuration

### Kubeconfig

The kubeconfig is at `kubernetes/kubeconfig`. Set the environment variable:

```bash
export KUBECONFIG=/path/to/home-cluster/kubernetes/kubeconfig
```

Or add to your shell profile.

### Talos Config

Talos config lives in `~/.talos/config` or wherever `TALOSCONFIG` points.

Regenerate it with:

```bash
task talos:kubeconfig
```

### 1Password

Authenticate:

```bash
eval $(op signin)
```

Check it works:

```bash
op user get --me
```

## Shell Setup

### Aliases

Add these to your `.zshrc` or `.bashrc`:

```bash
alias k='kubectl'
alias kc='kubecolor'
alias f='flux'
alias watch='viddy'
alias logs='stern'
```

### Completions

```bash
source <(kubectl completion zsh)
source <(flux completion zsh)
source <(talosctl completion zsh)
source <(helm completion zsh)
```

## Verify Everything Works

```bash
kubectl get nodes
talosctl version
flux check
op user get --me
```

## Updating Tools

```bash
# Homebrew
brew update && brew upgrade

# Krew plugins
kubectl krew upgrade

# Resync with Brewfile
task workstation:brew
```
