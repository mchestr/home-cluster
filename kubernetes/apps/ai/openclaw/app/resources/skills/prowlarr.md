---
name: prowlarr
description: Inspect the Prowlarr HTTP API during media investigations, especially indexer health, app sync, search failures, and download client integration
metadata:
  { "openclaw": { "emoji": "search", "homepage": "https://wiki.servarr.com/prowlarr" } }
user-invocable: true
disable-model-invocation: false
---

Use this skill when an alert, log line, or user question points at Prowlarr,
especially indexer failures, blocked searches, app sync errors, auth problems,
or Sonarr/Radarr missing releases.

Keep investigations read-only. Do not use POST/PUT/DELETE endpoints unless
explicitly told to remediate.

## Endpoint

In-cluster URL: `http://prowlarr.media.svc.cluster.local:9696`

OpenClaw has `PROWLARR_API_KEY` in the environment. Query with `curl` and the
`X-Api-Key` header:

```sh
curl -fsS -H "X-Api-Key: $${PROWLARR_API_KEY}" \
  "http://prowlarr.media.svc.cluster.local:9696/api/v1/system/status"
```

If the env var is missing, read the Kubernetes Secret directly:

```sh
APISERVER=https://kubernetes.default.svc
TOKEN="$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)"
CA=/var/run/secrets/kubernetes.io/serviceaccount/ca.crt
PROWLARR_API_KEY="$(curl -fsS --cacert "$CA" -H "Authorization: Bearer $TOKEN" \
  "$APISERVER/api/v1/namespaces/media/secrets/prowlarr-secret" \
  | jq -r '.data."PROWLARR__AUTH__APIKEY" | @base64d')"
```

Pipe responses through `jq` when available.

## Fast checks

System status and health:

```sh
curl -fsS -H "X-Api-Key: $${PROWLARR_API_KEY}" \
  "http://prowlarr.media.svc.cluster.local:9696/api/v1/system/status"
curl -fsS -H "X-Api-Key: $${PROWLARR_API_KEY}" \
  "http://prowlarr.media.svc.cluster.local:9696/api/v1/health"
```

Indexers and indexer status:

```sh
curl -fsS -H "X-Api-Key: $${PROWLARR_API_KEY}" \
  "http://prowlarr.media.svc.cluster.local:9696/api/v1/indexer"
curl -fsS -H "X-Api-Key: $${PROWLARR_API_KEY}" \
  "http://prowlarr.media.svc.cluster.local:9696/api/v1/indexerstatus"
```

Applications and download clients:

```sh
curl -fsS -H "X-Api-Key: $${PROWLARR_API_KEY}" \
  "http://prowlarr.media.svc.cluster.local:9696/api/v1/applications"
curl -fsS -H "X-Api-Key: $${PROWLARR_API_KEY}" \
  "http://prowlarr.media.svc.cluster.local:9696/api/v1/downloadclient"
```

## What to look for

- Disabled, rate-limited, or failing indexers.
- App sync failures to Sonarr or Radarr.
- Authentication, DNS, TLS, proxy, or FlareSolverr-style errors.
- Health warnings that explain missing search results in downstream apps.
- A mismatch between Prowlarr indexer status and Sonarr/Radarr indexer status.

## Investigation flow

- Start with `/api/v1/health`, then inspect indexer status.
- Cross-check Sonarr/Radarr queue and history if searches are not grabbing.
- Use VictoriaLogs for Prowlarr plus related Sonarr/Radarr logs around the
  failure time.
- Report the failing indexer or app sync target, the exact API error, and the
  safest next action.
