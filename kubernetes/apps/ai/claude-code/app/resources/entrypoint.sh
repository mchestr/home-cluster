#!/usr/bin/env bash
# Starts the Remote Control server. Every step is idempotent.
set -euo pipefail

REPO="$HOME/home-cluster"

# Self-updating after the first install.
command -v claude >/dev/null || curl -fsSL https://claude.ai/install.sh | bash

install -D -m 600 /scripts/kubeconfig.yaml "$HOME/.kube/config"
install -D -m 644 /scripts/CLAUDE.md "$HOME/.claude/CLAUDE.md"
# Attribution off, keeping the rest of settings.json.
node -e '
  const fs = require("fs"), p = process.env.HOME + "/.claude/settings.json";
  let s = {}; try { s = JSON.parse(fs.readFileSync(p, "utf8")); } catch {}
  s.attribution = { commit: "", pr: "" };
  fs.writeFileSync(p, JSON.stringify(s, null, 2) + "\n");
'

git config --global user.name "Mike Chester"
git config --global user.email "mike@chester.io"
# git push via GITHUB_TOKEN.
gh auth setup-git >/dev/null 2>&1 || true
[ -d "$REPO/.git" ] || git clone https://github.com/mchestr/home-cluster.git "$REPO"

# Version pinned in tools.env; a new pin replaces the registered entry.
. /scripts/tools.env
kubernetes_mcp="kubernetes-mcp-server@$KUBERNETES_MCP_SERVER_VERSION"
registered=$(claude mcp get kubernetes 2>/dev/null || true)
if ! grep -qxF "  Args: -y $kubernetes_mcp" <<<"$registered"; then
  claude mcp remove -s user kubernetes >/dev/null 2>&1 || true
  claude mcp add -s user kubernetes -- npx -y "$kubernetes_mcp" || true
fi
claude mcp get flux-operator >/dev/null 2>&1 \
  || claude mcp add -s user flux-operator -- flux-operator-mcp serve || true
# Home Assistant, only with HASS_TOKEN (a non-admin user's token, which
# /api/mcp/assist admits). claude expands the header on connect, so the token
# is not written to ~/.claude.json. A new URL replaces the registered entry.
if [ -n "${HASS_TOKEN:-}" ]; then
  hass_mcp_url=http://home-assistant.default.svc.cluster.local:8123/api/mcp/assist
  registered=$(claude mcp get home-assistant 2>/dev/null || true)
  if ! grep -qxF "  URL: $hass_mcp_url" <<<"$registered"; then
    claude mcp remove -s user home-assistant >/dev/null 2>&1 || true
    claude mcp add -s user --transport http home-assistant "$hass_mcp_url" \
      --header "Authorization: Bearer \${HASS_TOKEN}" || true
  fi
fi
for marketplace in eleboucher/memini anthropics/claude-code homeassistant-ai/skills; do
  claude plugin marketplace add "$marketplace" >/dev/null 2>&1 || true
done
for plugin in memini@memini commit-commands@claude-code-plugins home-assistant-skills@home-assistant-skills; do
  claude plugin list 2>/dev/null | grep -q "$plugin" \
    || claude plugin install "$plugin" >/dev/null 2>&1 \
    || echo "WARN: plugin $plugin install failed"
done

# Idle until the interactive bootstrap in README.md is done.
if [ ! -f "$HOME/.remote-control-ready" ]; then
  echo "claude-code: not bootstrapped; see kubernetes/apps/ai/claude-code/README.md"
  exec sleep infinity
fi

cd "$REPO"
git pull --ff-only -q || true

exec > >(perl /scripts/log-filter.pl) 2>&1
# Non-allowlisted tool calls wait for approval in the app.
exec claude remote-control \
  --name home-cluster \
  --spawn worktree \
  --permission-mode default
