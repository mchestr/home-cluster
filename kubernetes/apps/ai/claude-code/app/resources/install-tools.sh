#!/bin/sh
# Installs CLIs to ~/.local/bin when their tools.env version changes.
set -eu

. /scripts/tools.env

BIN=/home/claude/.local/bin
GH=https://github.com
mkdir -p "$BIN"

# install <name> <version> <url> [binary path in archive]
install() {
  [ "$(cat "$BIN/.$1ver" 2>/dev/null)" = "$2" ] && return 0
  echo "installing $1 $2"
  if [ -z "${4:-}" ]; then
    wget -qO "$BIN/$1" "$3"
  else
    rm -rf /tmp/x && mkdir -p /tmp/x
    wget -qO /tmp/x/a.tar "$3"
    case "$3" in
      *.zip) unzip -q /tmp/x/a.tar -d /tmp/x ;;
      *.tar.xz) tar -xJf /tmp/x/a.tar -C /tmp/x ;;
      *) tar -xzf /tmp/x/a.tar -C /tmp/x ;;
    esac
    cp "/tmp/x/$4" "$BIN/$1"
    rm -rf /tmp/x
  fi
  chmod +x "$BIN/$1"
  printf '%s' "$2" > "$BIN/.$1ver"
}

install kubectl "$KUBECTL_VERSION" \
  "https://dl.k8s.io/release/$KUBECTL_VERSION/bin/linux/amd64/kubectl"
install flux "$FLUX_VERSION" \
  "$GH/fluxcd/flux2/releases/download/$FLUX_VERSION/flux_${FLUX_VERSION#v}_linux_amd64.tar.gz" flux
install flux-operator-mcp "$FLUX_OPERATOR_VERSION" \
  "$GH/controlplaneio-fluxcd/flux-operator/releases/download/$FLUX_OPERATOR_VERSION/flux-operator-mcp_${FLUX_OPERATOR_VERSION#v}_linux_amd64.tar.gz" flux-operator-mcp
install talosctl "$TALOS_VERSION" \
  "$GH/siderolabs/talos/releases/download/$TALOS_VERSION/talosctl-linux-amd64"
install task "$TASK_VERSION" \
  "$GH/go-task/task/releases/download/$TASK_VERSION/task_linux_amd64.tar.gz" task
install gh "$GH_VERSION" \
  "$GH/cli/cli/releases/download/$GH_VERSION/gh_${GH_VERSION#v}_linux_amd64.tar.gz" "gh_${GH_VERSION#v}_linux_amd64/bin/gh"
install helm "$HELM_VERSION" \
  "https://get.helm.sh/helm-$HELM_VERSION-linux-amd64.tar.gz" linux-amd64/helm
install kustomize "$KUSTOMIZE_VERSION" \
  "$GH/kubernetes-sigs/kustomize/releases/download/kustomize%2F$KUSTOMIZE_VERSION/kustomize_${KUSTOMIZE_VERSION}_linux_amd64.tar.gz" kustomize
install yq "$YQ_VERSION" \
  "$GH/mikefarah/yq/releases/download/$YQ_VERSION/yq_linux_amd64"
install jq "$JQ_VERSION" \
  "$GH/jqlang/jq/releases/download/jq-$JQ_VERSION/jq-linux-amd64"
install minijinja-cli "$MINIJINJA_VERSION" \
  "$GH/mitsuhiko/minijinja/releases/download/$MINIJINJA_VERSION/minijinja-cli-x86_64-unknown-linux-musl.tar.xz" \
  minijinja-cli-x86_64-unknown-linux-musl/minijinja-cli
# For task terraform:*.
install terraform "$TERRAFORM_VERSION" \
  "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION#v}/terraform_${TERRAFORM_VERSION#v}_linux_amd64.zip" terraform
