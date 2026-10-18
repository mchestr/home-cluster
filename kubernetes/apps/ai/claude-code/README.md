# claude-code

Claude Code running in the cluster as a [Remote Control](https://code.claude.com/docs/en/remote-control.md)
server, so cluster issues can be fixed from claude.ai/code or the Claude app
without the Mac. It has the same reach as a local session: `cluster-admin`,
talosctl, gh with push access, and the kubernetes and flux-operator MCP servers.
The guard is the permission mode: anything outside the repo's
`.claude/settings.json` allowlist waits for approval in the app.

## Prerequisites

1Password item `claude-code` with:

- `GITHUB_TOKEN`: fine-grained PAT on `mchestr/home-cluster`, contents and pull
  requests read/write.
- `TALOSCONFIG`: contents of the admin `~/.talos/config`.
- `HASS_TOKEN`: long-lived access token of a non-admin Home Assistant user, for
  the Home Assistant MCP server (`/api/mcp/assist`, which serves only the
  entities exposed to Assist). Without this field the ExternalSecret does not
  sync and the pod cannot start; an empty value skips the server.

## One-time bootstrap

Remote Control needs a full claude.ai login (a `claude setup-token` token is
rejected) and an interactive first run. Until `~/.remote-control-ready` exists
the pod only sleeps.

```sh
kubectl exec -it -n ai deploy/claude-code -- bash
claude auth login                              # claude.ai account, paste the code
cd ~/home-cluster && claude remote-control     # answer y (enable) and y (trust), then Ctrl-C
touch ~/.remote-control-ready
exit
kubectl rollout restart -n ai deploy/claude-code
```

The session then shows up as `home-cluster` in claude.ai/code and the app; new
sessions started from there each get their own git worktree.

## Notes

- `~/.claude` (including the login) lives on the `claude-code` PVC, which is
  intentionally not backed up by VolSync. If it is lost, repeat the bootstrap.
- If the login expires, sessions stop making progress: exec in and run
  `claude auth login` again.
- Remote Control refuses to start if `ANTHROPIC_API_KEY`,
  `ANTHROPIC_AUTH_TOKEN`, `CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC` or
  `DISABLE_GROWTHBOOK` is set.
- No `op` CLI, so 1Password-backed tasks (terraform, `talos:apply-node`) still
  need the Mac.
