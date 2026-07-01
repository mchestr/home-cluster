---
name: radarr
description: Inspect the Radarr HTTP API during media investigations, especially Radarr queue, health, wanted, history, indexer, download client, and import failures
metadata:
  { "openclaw": { "emoji": "movie", "homepage": "https://wiki.servarr.com/radarr" } }
user-invocable: true
disable-model-invocation: false
---

Use this skill when an alert, log line, or user question points at Radarr,
especially `RadarrQueueNotEmpty`, stalled imports, missing movies,
download client issues, indexer failures, or API/widget problems.

Keep investigations read-only. Do not use POST/PUT/DELETE endpoints unless
explicitly told to remediate.

## Endpoint

In-cluster URL: `http://radarr.media.svc.cluster.local:7878`

OpenClaw has `RADARR_API_KEY` in the environment. Query with `curl` and the
`X-Api-Key` header:

```sh
curl -fsS -H "X-Api-Key: $${RADARR_API_KEY}" \
  "http://radarr.media.svc.cluster.local:7878/api/v3/system/status"
```

If the env var is missing, read the Kubernetes Secret directly:

```sh
APISERVER=https://kubernetes.default.svc
TOKEN="$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)"
CA=/var/run/secrets/kubernetes.io/serviceaccount/ca.crt
RADARR_API_KEY="$(curl -fsS --cacert "$CA" -H "Authorization: Bearer $TOKEN" \
  "$APISERVER/api/v1/namespaces/media/secrets/radarr-secret" \
  | jq -r '.data."RADARR__AUTH__APIKEY" | @base64d')"
```

Pipe through `jq` when available.

## Fast checks

System status and health:

```sh
curl -fsS -H "X-Api-Key: $${RADARR_API_KEY}" \
  "http://radarr.media.svc.cluster.local:7878/api/v3/system/status"
curl -fsS -H "X-Api-Key: $${RADARR_API_KEY}" \
  "http://radarr.media.svc.cluster.local:7878/api/v3/health"
```

Queue details for stuck downloads/imports:

```sh
curl -fsS -H "X-Api-Key: $${RADARR_API_KEY}" \
  "http://radarr.media.svc.cluster.local:7878/api/v3/queue?page=1&pageSize=100&sortKey=timeleft&sortDirection=ascending&includeUnknownMovieItems=true&includeMovie=true"
```

Recent queue/import/download history:

```sh
curl -fsS -H "X-Api-Key: $${RADARR_API_KEY}" \
  "http://radarr.media.svc.cluster.local:7878/api/v3/history?page=1&pageSize=100&sortKey=date&sortDirection=descending"
```

Wanted missing movies:

```sh
curl -fsS -H "X-Api-Key: $${RADARR_API_KEY}" \
  "http://radarr.media.svc.cluster.local:7878/api/v3/wanted/missing?page=1&pageSize=50&sortKey=releaseDate&sortDirection=descending"
```

Indexer and download client status:

```sh
curl -fsS -H "X-Api-Key: $${RADARR_API_KEY}" \
  "http://radarr.media.svc.cluster.local:7878/api/v3/indexer/status"
curl -fsS -H "X-Api-Key: $${RADARR_API_KEY}" \
  "http://radarr.media.svc.cluster.local:7878/api/v3/downloadclient/status"
```

## What to look for

- Queue items with `trackedDownloadStatus` or `statusMessages` explaining
  why import is blocked.
- Download client warnings, unavailable indexers, auth failures, or DNS/TLS
  errors in health/status responses.
- Repeated grab/import failures in history close to the alert `startsAt`.
- Path problems involving `/data`, `/complete/radarr`, permissions, or NFS.
- A mismatch between Radarr queue data and exporter metrics
  (`radarr_queue_total`).

## Investigation flow

- Start with `/api/v3/queue` for `RadarrQueueNotEmpty`.
- Use `/api/v3/health`, indexer status, and download client status to
  explain why queue items are stuck.
- Cross-check with VictoriaLogs for Radarr and related download client logs.
- If the API is unhealthy or unreachable, inspect Kubernetes events, pod
  status, service endpoints, and Flux state before blaming Radarr itself.
- Report the exact queued movie, blockage reason, and safest next action.
