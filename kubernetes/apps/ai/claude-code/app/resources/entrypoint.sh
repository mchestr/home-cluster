#!/usr/bin/env bash
# Starts Claude Code's Remote Control server. Every step is idempotent, so the
# state kept on the PVC (login, plugins, repo checkout) survives restarts.
set -euo pipefail

REPO="$HOME/home-cluster"

# Native claude binary on the PVC; it keeps itself up to date after this.
command -v claude >/dev/null || curl -fsSL https://claude.ai/install.sh | bash

# Files managed in git: the ServiceAccount kubeconfig (so kubectl, flux, helm
# and the MCP servers behave as with a normal kubeconfig) and the user-level
# CLAUDE.md.
install -D -m 600 /scripts/kubeconfig.yaml "$HOME/.kube/config"
install -D -m 644 /scripts/CLAUDE.md "$HOME/.claude/CLAUDE.md"
# Commit and PR attribution off, keeping the rest of settings.json.
node -e '
  const fs = require("fs"), p = process.env.HOME + "/.claude/settings.json";
  let s = {}; try { s = JSON.parse(fs.readFileSync(p, "utf8")); } catch {}
  s.attribution = { commit: "", pr: "" };
  fs.writeFileSync(p, JSON.stringify(s, null, 2) + "\n");
'

git config --global user.name "Mike Chester"
git config --global user.email "mike@chester.io"
# gh reads GITHUB_TOKEN from the env; this makes git push use it too.
gh auth setup-git >/dev/null 2>&1 || true
[ -d "$REPO/.git" ] || git clone https://github.com/mchestr/home-cluster.git "$REPO"

# Same MCP servers and plugins as the Mac session.
claude mcp get kubernetes >/dev/null 2>&1 \
  || claude mcp add -s user kubernetes -- npx -y kubernetes-mcp-server@latest || true
claude mcp get flux-operator >/dev/null 2>&1 \
  || claude mcp add -s user flux-operator -- flux-operator-mcp serve || true
for marketplace in eleboucher/memini anthropics/claude-code homeassistant-ai/skills; do
  claude plugin marketplace add "$marketplace" >/dev/null 2>&1 || true
done
for plugin in memini@memini commit-commands@claude-code-plugins home-assistant-skills@home-assistant-skills; do
  claude plugin list 2>/dev/null | grep -q "$plugin" \
    || claude plugin install "$plugin" >/dev/null 2>&1 \
    || echo "WARN: plugin $plugin install failed"
done

# Remote Control needs a full claude.ai login plus a one-time interactive
# "Enable Remote Control?" / workspace-trust answer, neither of which works
# without a TTY. Idle until that bootstrap (README.md) has been done.
if [ ! -f "$HOME/.remote-control-ready" ]; then
  echo "claude-code: not bootstrapped; see kubernetes/apps/ai/claude-code/README.md"
  exec sleep infinity
fi

cd "$REPO"
git pull --ff-only -q || true

exec > >(perl /scripts/log-filter.pl) 2>&1
# default permission mode: every tool call outside the repo's allowlist is
# forwarded to claude.ai / the app for approval. exec keeps claude as PID 1.
exec claude remote-control \
  --name home-cluster \
  --spawn worktree \
  --permission-mode default
