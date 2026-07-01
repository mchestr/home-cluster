---
name: jellyfin
description: Inspect the Jellyfin HTTP API during media investigations, especially system info, sessions, libraries, users, and playback problems
metadata:
  { "openclaw": { "emoji": "jellyfin", "homepage": "https://api.jellyfin.org/" } }
user-invocable: true
disable-model-invocation: false
---

Use this skill when an alert, log line, or user question points at Jellyfin,
especially playback, library refresh, missing media, sessions, or API/widget
problems.

Keep investigations read-only. Do not terminate sessions, rescan libraries, or
edit users unless explicitly told to remediate.

## Endpoint

In-cluster URL: `http://jellyfin.media.svc.cluster.local:8096`

OpenClaw has `JELLYFIN_API_KEY` in the environment. Query with `curl` and the
`X-Emby-Token` header:

```sh
curl -fsS -H "X-Emby-Token: ${JELLYFIN_API_KEY}" \
  "http://jellyfin.media.svc.cluster.local:8096/System/Info/Public"
```

If the env var is missing, read the homepage Secret directly:

```sh
APISERVER=https://kubernetes.default.svc
TOKEN="$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)"
CA=/var/run/secrets/kubernetes.io/serviceaccount/ca.crt
JELLYFIN_API_KEY="$(curl -fsS --cacert "$CA" -H "Authorization: Bearer $TOKEN" \
  "$APISERVER/api/v1/namespaces/default/secrets/homepage-secret" \
  | jq -r '.data.HOMEPAGE_VAR_JELLYFIN_API_KEY | @base64d')"
```

Pipe responses through `jq` when available.

## Fast checks

System info and sessions:

```sh
curl -fsS -H "X-Emby-Token: ${JELLYFIN_API_KEY}" \
  "http://jellyfin.media.svc.cluster.local:8096/System/Info"
curl -fsS -H "X-Emby-Token: ${JELLYFIN_API_KEY}" \
  "http://jellyfin.media.svc.cluster.local:8096/Sessions"
```

Libraries and users:

```sh
curl -fsS -H "X-Emby-Token: ${JELLYFIN_API_KEY}" \
  "http://jellyfin.media.svc.cluster.local:8096/Library/VirtualFolders"
curl -fsS -H "X-Emby-Token: ${JELLYFIN_API_KEY}" \
  "http://jellyfin.media.svc.cluster.local:8096/Users"
```

Scheduled tasks:

```sh
curl -fsS -H "X-Emby-Token: ${JELLYFIN_API_KEY}" \
  "http://jellyfin.media.svc.cluster.local:8096/ScheduledTasks"
```

## What to look for

- Active sessions with direct play/transcode failures or stuck playback.
- Library folders that do not match Sonarr/Radarr import paths.
- Scheduled library scans stuck or repeatedly failing.
- API token/auth failures that affect Homepage or jellyplex-watched.
- Server version or plugin issues after upgrades.

## Investigation flow

- Start with system info and active sessions.
- Check virtual folders and scheduled tasks for missing media.
- Cross-check Sonarr/Radarr history and Jellyseerr requests for the affected
  title.
- Report the user/session/library, scan state, and likely source of the issue.
