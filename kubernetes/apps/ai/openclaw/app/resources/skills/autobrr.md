---
name: autobrr
description: Inspect the autobrr HTTP API during media investigations, especially IRC/indexer feed health, filters, releases, and download-client pushes
metadata:
  { "openclaw": { "emoji": "autobrr", "homepage": "https://autobrr.com/" } }
user-invocable: true
disable-model-invocation: false
---

Use this skill when an alert, log line, or user question points at autobrr,
especially missed announces, filter mismatch, failed pushes to qBittorrent or
SABnzbd, IRC/feed connectivity, or API/widget problems.

Keep investigations read-only. Do not run tests, push releases, edit filters,
or modify actions unless explicitly told to remediate.

## Endpoint

In-cluster URL: `http://autobrr.media.svc.cluster.local:7474`

OpenClaw has `AUTOBRR_API_KEY` in the environment. Query with `curl` and the
`X-Api-Token` header:

```sh
curl -fsS -H "X-Api-Token: ${AUTOBRR_API_KEY}" \
  "http://autobrr.media.svc.cluster.local:7474/api/healthz/liveness"
```

If the env var is missing, read the homepage Secret directly:

```sh
APISERVER=https://kubernetes.default.svc
TOKEN="$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)"
CA=/var/run/secrets/kubernetes.io/serviceaccount/ca.crt
AUTOBRR_API_KEY="$(curl -fsS --cacert "$CA" -H "Authorization: Bearer $TOKEN" \
  "$APISERVER/api/v1/namespaces/default/secrets/homepage-secret" \
  | jq -r '.data.HOMEPAGE_VAR_AUTOBRR_API_KEY | @base64d')"
```

Pipe responses through `jq` when available. If the token header is rejected,
check the live OpenAPI docs or app logs before trying a session login.

## Fast checks

Health:

```sh
curl -fsS -H "X-Api-Token: ${AUTOBRR_API_KEY}" \
  "http://autobrr.media.svc.cluster.local:7474/api/healthz/liveness"
curl -fsS -H "X-Api-Token: ${AUTOBRR_API_KEY}" \
  "http://autobrr.media.svc.cluster.local:7474/api/healthz/readiness"
```

Common read-only API surfaces to try when available in the running version:

```sh
curl -fsS -H "X-Api-Token: ${AUTOBRR_API_KEY}" \
  "http://autobrr.media.svc.cluster.local:7474/api/filters"
curl -fsS -H "X-Api-Token: ${AUTOBRR_API_KEY}" \
  "http://autobrr.media.svc.cluster.local:7474/api/indexers"
curl -fsS -H "X-Api-Token: ${AUTOBRR_API_KEY}" \
  "http://autobrr.media.svc.cluster.local:7474/api/releases?limit=50"
```

## What to look for

- Filters that never match expected releases.
- Indexer or IRC/feed connectivity errors.
- Failed action pushes to qBittorrent or SABnzbd.
- API token or OIDC issues after auth changes.
- Release history that disagrees with Sonarr/Radarr searches.

## Investigation flow

- Start with health and VictoriaLogs for `app:"autobrr"`.
- Inspect releases, filters, and indexers if the read-only endpoints are
  accepted by the running version.
- Cross-check qBittorrent or SABnzbd for the expected pushed download.
- Report the release, filter, indexer, action target, and exact failure point.
