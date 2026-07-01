---
name: cross-seed
description: Inspect the cross-seed HTTP API during torrent investigations, especially daemon health, webhook failures, injection state, and qBittorrent handoff
metadata:
  { "openclaw": { "emoji": "cross-seed", "homepage": "https://www.cross-seed.org/" } }
user-invocable: true
disable-model-invocation: false
---

Use this skill when an alert, log line, or user question points at cross-seed,
especially webhook failures, unauthorized API attempts, missed injections, or
qBittorrent category/path issues.

Keep investigations read-only. Do not run search, inject, webhook, or mutate
endpoints unless explicitly told to remediate.

## Endpoint

In-cluster URL: `http://cross-seed.media.svc.cluster.local:2468`

OpenClaw has `CROSS_SEED_API_KEY` in the environment. Query with `curl` and the
`X-Api-Key` header:

```sh
curl -fsS -H "X-Api-Key: $${CROSS_SEED_API_KEY}" \
  "http://cross-seed.media.svc.cluster.local:2468/api/ping"
```

If the env var is missing, read the qBittorrent Secret directly:

```sh
APISERVER=https://kubernetes.default.svc
TOKEN="$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)"
CA=/var/run/secrets/kubernetes.io/serviceaccount/ca.crt
CROSS_SEED_API_KEY="$(curl -fsS --cacert "$CA" -H "Authorization: Bearer $TOKEN" \
  "$APISERVER/api/v1/namespaces/media/secrets/qbittorrent-secret" \
  | jq -r '.data.CROSS_SEED_API_KEY | @base64d')"
```

Pipe responses through `jq` when available.

## Fast checks

Ping and daemon logs:

```sh
curl -fsS -H "X-Api-Key: $${CROSS_SEED_API_KEY}" \
  "http://cross-seed.media.svc.cluster.local:2468/api/ping"
```

Configuration is mounted from `cross-seed-secret` as `config.js`. To inspect
the rendered config without exposing API keys:

```sh
APISERVER=https://kubernetes.default.svc
TOKEN="$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)"
CA=/var/run/secrets/kubernetes.io/serviceaccount/ca.crt
curl -fsS --cacert "$CA" -H "Authorization: Bearer $TOKEN" \
  "$APISERVER/api/v1/namespaces/media/secrets/cross-seed-secret" \
  | jq -r '.data."config.js" | @base64d' \
  | sed -E 's/(apiKey: ")[^"]+/\1REDACTED/g; s/(apikey=)[^"`]+/\1REDACTED/g'
```

## What to look for

- Unauthorized API access attempts in VictoriaLogs.
- Mismatched qBittorrent URL, category, or link directory.
- Broken Prowlarr Torznab URLs or stale indexer IDs.
- Radarr/Sonarr API key errors in the rendered config.
- Path issues involving `/data/downloads/torrents/complete/cross-seed`.

## Investigation flow

- Start with `/api/ping`.
- Inspect VictoriaLogs for `app:"cross-seed"` near the failure.
- Cross-check qBittorrent categories and torrent state for injected items.
- If searches are not producing results, inspect Prowlarr indexer status.
- Report whether the problem is API auth, indexer search, qBittorrent handoff,
  or filesystem/path behavior.
