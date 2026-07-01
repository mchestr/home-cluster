---
name: sabnzbd
description: Inspect the SABnzbd HTTP API during download investigations, especially queue, history, warnings, server connectivity, and failed NZB downloads
metadata:
  { "openclaw": { "emoji": "usenet", "homepage": "https://sabnzbd.org/wiki/configuration/4.0/api" } }
user-invocable: true
disable-model-invocation: false
---

Use this skill when an alert, log line, or user question points at SABnzbd,
especially stalled downloads, failed jobs, server issues, low disk space, or
Sonarr/Radarr import problems involving Usenet.

Keep investigations read-only. Do not pause, delete, retry, or modify jobs
unless explicitly told to remediate.

## Endpoint

In-cluster URL: `http://sabnzbd.media.svc.cluster.local:8080`

OpenClaw has `SABNZBD_API_KEY` in the environment. SABnzbd uses the `apikey`
query parameter:

```sh
curl -fsS \
  "http://sabnzbd.media.svc.cluster.local:8080/api?mode=version&output=json&apikey=$${SABNZBD_API_KEY}"
```

If the env var is missing, read the Kubernetes Secret directly:

```sh
APISERVER=https://kubernetes.default.svc
TOKEN="$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)"
CA=/var/run/secrets/kubernetes.io/serviceaccount/ca.crt
SABNZBD_API_KEY="$(curl -fsS --cacert "$CA" -H "Authorization: Bearer $TOKEN" \
  "$APISERVER/api/v1/namespaces/media/secrets/sabnzbd-secret" \
  | jq -r '.data."SABNZBD__API_KEY" | @base64d')"
```

Pipe responses through `jq` when available.

## Fast checks

Version and full queue:

```sh
curl -fsS \
  "http://sabnzbd.media.svc.cluster.local:8080/api?mode=version&output=json&apikey=$${SABNZBD_API_KEY}"
curl -fsS \
  "http://sabnzbd.media.svc.cluster.local:8080/api?mode=queue&output=json&apikey=$${SABNZBD_API_KEY}"
```

History and warnings:

```sh
curl -fsS \
  "http://sabnzbd.media.svc.cluster.local:8080/api?mode=history&output=json&limit=50&apikey=$${SABNZBD_API_KEY}"
curl -fsS \
  "http://sabnzbd.media.svc.cluster.local:8080/api?mode=warnings&output=json&apikey=$${SABNZBD_API_KEY}"
```

Server statistics:

```sh
curl -fsS \
  "http://sabnzbd.media.svc.cluster.local:8080/api?mode=server_stats&output=json&apikey=$${SABNZBD_API_KEY}"
```

## What to look for

- Queue items stuck in fetching, repairing, unpacking, or post-processing.
- Warnings about server auth, quota, retention, missing articles, or disk
  space.
- Failed history items that correspond to Sonarr/Radarr import failures.
- Path problems involving `/data`, `/complete`, `/incomplete`, or permissions.
- Server stats showing one server disabled or erroring repeatedly.

## Investigation flow

- Start with queue, then warnings, then recent history.
- Cross-check the matching Sonarr/Radarr queue item and history event.
- Use VictoriaLogs for SABnzbd and the relevant Servarr app around the same
  timestamp.
- Report the job name, SABnzbd stage, warning/error text, and safest next
  action.
