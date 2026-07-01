---
name: plex
description: Inspect the Plex HTTP API during media investigations, especially server identity, sessions, libraries, scans, and playback problems
metadata:
  { "openclaw": { "emoji": "plex", "homepage": "https://www.plex.tv/" } }
user-invocable: true
disable-model-invocation: false
---

Use this skill when an alert, log line, or user question points at Plex,
especially active playback, missing media, library scan state, metadata issues,
or Plex token/widget problems.

Keep investigations read-only. Do not terminate sessions, refresh libraries,
or edit media unless explicitly told to remediate.

## Endpoint

In-cluster URL: `http://plex.media.svc.cluster.local:32400`

OpenClaw has `PLEX_API_TOKEN` in the environment. Query with `curl` and the
`X-Plex-Token` query parameter:

```sh
curl -fsS \
  "http://plex.media.svc.cluster.local:32400/identity?X-Plex-Token=${PLEX_API_TOKEN}"
```

If the env var is missing, read the homepage Secret directly:

```sh
APISERVER=https://kubernetes.default.svc
TOKEN="$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)"
CA=/var/run/secrets/kubernetes.io/serviceaccount/ca.crt
PLEX_API_TOKEN="$(curl -fsS --cacert "$CA" -H "Authorization: Bearer $TOKEN" \
  "$APISERVER/api/v1/namespaces/default/secrets/homepage-secret" \
  | jq -r '.data.HOMEPAGE_VAR_PLEX_API_KEY | @base64d')"
```

Plex usually returns XML. Use `xq`, `xmllint`, or plain text inspection when
available.

## Fast checks

Identity, server status, and active sessions:

```sh
curl -fsS \
  "http://plex.media.svc.cluster.local:32400/identity?X-Plex-Token=${PLEX_API_TOKEN}"
curl -fsS \
  "http://plex.media.svc.cluster.local:32400/status/sessions?X-Plex-Token=${PLEX_API_TOKEN}"
curl -fsS \
  "http://plex.media.svc.cluster.local:32400/status/sessions/history/all?X-Plex-Token=${PLEX_API_TOKEN}"
```

Libraries and scans:

```sh
curl -fsS \
  "http://plex.media.svc.cluster.local:32400/library/sections?X-Plex-Token=${PLEX_API_TOKEN}"
curl -fsS \
  "http://plex.media.svc.cluster.local:32400/butler/tasks?X-Plex-Token=${PLEX_API_TOKEN}"
```

## What to look for

- Active sessions with transcode, bandwidth, or buffering symptoms.
- Libraries missing from `/library/sections`.
- Metadata or scan tasks that explain newly imported media not appearing.
- Token/auth problems that also affect Tautulli, Kometa, Bazarr, or Homepage.
- Path mismatches between Plex libraries and `/data` imports.

## Investigation flow

- Start with identity, then active sessions.
- Use library sections for missing media or scan questions.
- Cross-check Tautulli for watch history and Jellyseerr/Sonarr/Radarr for the
  request/import path.
- Report the server identity, affected library/session, and the likely broken
  handoff point.
