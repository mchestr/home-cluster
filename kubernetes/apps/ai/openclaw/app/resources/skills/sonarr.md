---
name: sonarr
description: Inspect the Sonarr HTTP API during media investigations, especially Sonarr queue, health, wanted, history, indexer, download client, and import failures
metadata:
  { "openclaw": { "emoji": "tv", "homepage": "https://wiki.servarr.com/sonarr" } }
user-invocable: true
disable-model-invocation: false
---

Use this skill when an alert, log line, or user question points at Sonarr,
especially `SonarrQueueNotEmpty`, stalled imports, missing episodes,
download client issues, indexer failures, or API/widget problems.

Keep investigations read-only. Do not use POST/PUT/DELETE endpoints unless
explicitly told to remediate.

## Endpoint

In-cluster URL: `http://sonarr.media.svc.cluster.local:8989`

OpenClaw has `SONARR_API_KEY` in the environment. Query with `curl` and the
`X-Api-Key` header:

```sh
curl -fsS -H "X-Api-Key: $${SONARR_API_KEY}" \
  "http://sonarr.media.svc.cluster.local:8989/api/v3/system/status"
```

If the env var is missing, read the Kubernetes Secret directly:

```sh
APISERVER=https://kubernetes.default.svc
TOKEN="$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)"
CA=/var/run/secrets/kubernetes.io/serviceaccount/ca.crt
SONARR_API_KEY="$(curl -fsS --cacert "$CA" -H "Authorization: Bearer $TOKEN" \
  "$APISERVER/api/v1/namespaces/media/secrets/sonarr-secret" \
  | jq -r '.data."SONARR__AUTH__APIKEY" | @base64d')"
```

Pipe through `jq` when available.

## Fast checks

System status and health:

```sh
curl -fsS -H "X-Api-Key: $${SONARR_API_KEY}" \
  "http://sonarr.media.svc.cluster.local:8989/api/v3/system/status"
curl -fsS -H "X-Api-Key: $${SONARR_API_KEY}" \
  "http://sonarr.media.svc.cluster.local:8989/api/v3/health"
```

Queue details for stuck downloads/imports:

```sh
curl -fsS -H "X-Api-Key: $${SONARR_API_KEY}" \
  "http://sonarr.media.svc.cluster.local:8989/api/v3/queue?page=1&pageSize=100&sortKey=timeleft&sortDirection=ascending&includeUnknownSeriesItems=true&includeSeries=true&includeEpisode=true"
```

Recent queue/import/download history:

```sh
curl -fsS -H "X-Api-Key: $${SONARR_API_KEY}" \
  "http://sonarr.media.svc.cluster.local:8989/api/v3/history?page=1&pageSize=100&sortKey=date&sortDirection=descending"
```

Wanted missing episodes:

```sh
curl -fsS -H "X-Api-Key: $${SONARR_API_KEY}" \
  "http://sonarr.media.svc.cluster.local:8989/api/v3/wanted/missing?page=1&pageSize=50&sortKey=airDateUtc&sortDirection=descending"
```

Indexer and download client status:

```sh
curl -fsS -H "X-Api-Key: $${SONARR_API_KEY}" \
  "http://sonarr.media.svc.cluster.local:8989/api/v3/indexer/status"
curl -fsS -H "X-Api-Key: $${SONARR_API_KEY}" \
  "http://sonarr.media.svc.cluster.local:8989/api/v3/downloadclient/status"
```

## What to look for

- Queue items with `trackedDownloadStatus` or `statusMessages` explaining
  why import is blocked.
- Download client warnings, unavailable indexers, auth failures, or DNS/TLS
  errors in health/status responses.
- Repeated grab/import failures in history close to the alert `startsAt`.
- Path problems involving `/data`, `/complete/sonarr`, permissions, or NFS.
- A mismatch between Sonarr queue data and exporter metrics
  (`sonarr_queue_total`).

## Investigation flow

- Start with `/api/v3/queue` for `SonarrQueueNotEmpty`.
- Use `/api/v3/health`, indexer status, and download client status to
  explain why queue items are stuck.
- Cross-check with VictoriaLogs for Sonarr and related download client logs.
- If the API is unhealthy or unreachable, inspect Kubernetes events, pod
  status, service endpoints, and Flux state before blaming Sonarr itself.
- Report the exact queued series/episode, blockage reason, and safest next
  action.
