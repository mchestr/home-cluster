---
name: bazarr
description: Inspect the Bazarr HTTP API during media investigations, especially subtitle providers, wanted subtitles, health, and Sonarr/Radarr integration
metadata:
  { "openclaw": { "emoji": "subtitles", "homepage": "https://wiki.bazarr.media/" } }
user-invocable: true
disable-model-invocation: false
---

Use this skill when an alert, log line, or user question points at Bazarr,
especially missing subtitles, provider failures, bad subtitles, or sync issues
with Sonarr, Radarr, Plex, or Jellyfin.

Keep investigations read-only. Do not use POST/PUT/DELETE endpoints unless
explicitly told to remediate.

## Endpoint

In-cluster URL: `http://bazarr.media.svc.cluster.local:6767`

OpenClaw has `BAZARR_API_KEY` in the environment. Query with `curl` and the
`X-API-KEY` header:

```sh
curl -fsS -H "X-API-KEY: $${BAZARR_API_KEY}" \
  "http://bazarr.media.svc.cluster.local:6767/api/system/status"
```

If the env var is missing, read the Kubernetes Secret directly:

```sh
APISERVER=https://kubernetes.default.svc
TOKEN="$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)"
CA=/var/run/secrets/kubernetes.io/serviceaccount/ca.crt
BAZARR_API_KEY="$(curl -fsS --cacert "$CA" -H "Authorization: Bearer $TOKEN" \
  "$APISERVER/api/v1/namespaces/media/secrets/bazarr-secret" \
  | jq -r '.data."BAZARR__API_KEY" | @base64d')"
```

Pipe responses through `jq` when available. If an endpoint shape changed,
open `http://bazarr.media.svc.cluster.local:6767/api/swaggerui` or fetch
`/api/swagger.json` for the live API schema.

## Fast checks

System status and health:

```sh
curl -fsS -H "X-API-KEY: $${BAZARR_API_KEY}" \
  "http://bazarr.media.svc.cluster.local:6767/api/system/status"
curl -fsS -H "X-API-KEY: $${BAZARR_API_KEY}" \
  "http://bazarr.media.svc.cluster.local:6767/api/system/health"
```

Wanted subtitles and provider state:

```sh
curl -fsS -H "X-API-KEY: $${BAZARR_API_KEY}" \
  "http://bazarr.media.svc.cluster.local:6767/api/episodes/wanted"
curl -fsS -H "X-API-KEY: $${BAZARR_API_KEY}" \
  "http://bazarr.media.svc.cluster.local:6767/api/movies/wanted"
curl -fsS -H "X-API-KEY: $${BAZARR_API_KEY}" \
  "http://bazarr.media.svc.cluster.local:6767/api/providers"
```

## What to look for

- Provider authentication, throttling, or ban messages.
- Wanted subtitles that are stuck on a single provider or language.
- Sonarr/Radarr connection errors and mismatched media paths.
- Plex token problems when subtitle refreshes trigger library scans.
- Path or permission problems involving `/data`.

## Investigation flow

- Start with system health, then wanted subtitles for the affected media type.
- Inspect providers before blaming Sonarr, Radarr, or the media files.
- Cross-check VictoriaLogs for Bazarr near the missing subtitle event.
- Report the affected title, language, provider error, and whether the next
  action is provider config, path mapping, or manual subtitle cleanup.
