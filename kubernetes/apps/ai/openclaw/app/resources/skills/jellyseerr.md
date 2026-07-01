---
name: jellyseerr
description: Inspect the Jellyseerr HTTP API during media investigations, especially request health, pending requests, media status, and Sonarr/Radarr handoff issues
metadata:
  { "openclaw": { "emoji": "requests", "homepage": "https://docs.jellyseerr.dev/" } }
user-invocable: true
disable-model-invocation: false
---

Use this skill when an alert, log line, or user question points at Jellyseerr,
especially stuck requests, failed approvals, missing media handoff, or user
request visibility problems.

Keep investigations read-only. Do not use POST/PUT/DELETE endpoints unless
explicitly told to remediate.

## Endpoint

In-cluster URL: `http://jellyseerr.media.svc.cluster.local:5055`

OpenClaw has `JELLYSEERR_API_KEY` in the environment. Query with `curl` and
the `X-Api-Key` header:

```sh
curl -fsS -H "X-Api-Key: ${JELLYSEERR_API_KEY}" \
  "http://jellyseerr.media.svc.cluster.local:5055/api/v1/status"
```

If the env var is missing, read the Kubernetes Secret directly:

```sh
APISERVER=https://kubernetes.default.svc
TOKEN="$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)"
CA=/var/run/secrets/kubernetes.io/serviceaccount/ca.crt
JELLYSEERR_API_KEY="$(curl -fsS --cacert "$CA" -H "Authorization: Bearer $TOKEN" \
  "$APISERVER/api/v1/namespaces/media/secrets/jellyseerr-secret" \
  | jq -r '.data.API_KEY | @base64d')"
```

Pipe responses through `jq` when available.

## Fast checks

Status and settings:

```sh
curl -fsS -H "X-Api-Key: ${JELLYSEERR_API_KEY}" \
  "http://jellyseerr.media.svc.cluster.local:5055/api/v1/status"
curl -fsS -H "X-Api-Key: ${JELLYSEERR_API_KEY}" \
  "http://jellyseerr.media.svc.cluster.local:5055/api/v1/settings/main"
```

Recent and pending requests:

```sh
curl -fsS -H "X-Api-Key: ${JELLYSEERR_API_KEY}" \
  "http://jellyseerr.media.svc.cluster.local:5055/api/v1/request?take=50&skip=0&sort=added&filter=all"
curl -fsS -H "X-Api-Key: ${JELLYSEERR_API_KEY}" \
  "http://jellyseerr.media.svc.cluster.local:5055/api/v1/request?take=50&skip=0&sort=added&filter=pending"
```

Issue list:

```sh
curl -fsS -H "X-Api-Key: ${JELLYSEERR_API_KEY}" \
  "http://jellyseerr.media.svc.cluster.local:5055/api/v1/issue?take=50&skip=0&sort=created&filter=all"
```

## What to look for

- Pending requests that never reached Sonarr or Radarr.
- Requests marked available in Jellyseerr but missing from Jellyfin/Plex.
- Service settings that point at the wrong Sonarr/Radarr instance or root path.
- User-facing issues that line up with media import failures.
- Database or auth errors in logs around request creation.

## Investigation flow

- Start with status, then recent requests.
- For a request that was handed off, inspect the matching Sonarr/Radarr queue
  and history.
- If media exists but does not show available, inspect Jellyfin/Plex sessions
  and library metadata refresh state.
- Report the request title, status, target app, and the broken handoff point.
