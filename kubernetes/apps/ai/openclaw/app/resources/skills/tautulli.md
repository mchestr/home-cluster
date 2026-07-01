---
name: tautulli
description: Inspect the Tautulli HTTP API during Plex investigations, especially activity, history, library stats, and Plex server reachability
metadata:
  { "openclaw": { "emoji": "stats", "homepage": "https://github.com/Tautulli/Tautulli/wiki/Tautulli-API-Reference" } }
user-invocable: true
disable-model-invocation: false
---

Use this skill when an alert, log line, or user question points at Tautulli,
especially Plex watch history, current sessions, library stats, notification
failures, or Plex server connectivity.

Keep investigations read-only. Do not use commands that terminate sessions,
delete history, or modify notification settings unless explicitly told to
remediate.

## Endpoint

In-cluster URL: `http://tautulli.media.svc.cluster.local:8181`

OpenClaw has `TAUTULLI_API_KEY` in the environment. Tautulli uses the `apikey`
query parameter:

```sh
curl -fsS \
  "http://tautulli.media.svc.cluster.local:8181/api/v2?apikey=${TAUTULLI_API_KEY}&cmd=status"
```

If the env var is missing, read the homepage Secret directly:

```sh
APISERVER=https://kubernetes.default.svc
TOKEN="$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)"
CA=/var/run/secrets/kubernetes.io/serviceaccount/ca.crt
TAUTULLI_API_KEY="$(curl -fsS --cacert "$CA" -H "Authorization: Bearer $TOKEN" \
  "$APISERVER/api/v1/namespaces/default/secrets/homepage-secret" \
  | jq -r '.data.HOMEPAGE_VAR_TAUTULLI_API_KEY | @base64d')"
```

Pipe responses through `jq` when available.

## Fast checks

Status, server info, and active streams:

```sh
curl -fsS \
  "http://tautulli.media.svc.cluster.local:8181/api/v2?apikey=${TAUTULLI_API_KEY}&cmd=status"
curl -fsS \
  "http://tautulli.media.svc.cluster.local:8181/api/v2?apikey=${TAUTULLI_API_KEY}&cmd=get_server_info"
curl -fsS \
  "http://tautulli.media.svc.cluster.local:8181/api/v2?apikey=${TAUTULLI_API_KEY}&cmd=get_activity"
```

Libraries, recent media, and history:

```sh
curl -fsS \
  "http://tautulli.media.svc.cluster.local:8181/api/v2?apikey=${TAUTULLI_API_KEY}&cmd=get_libraries"
curl -fsS \
  "http://tautulli.media.svc.cluster.local:8181/api/v2?apikey=${TAUTULLI_API_KEY}&cmd=get_recently_added&count=25"
curl -fsS \
  "http://tautulli.media.svc.cluster.local:8181/api/v2?apikey=${TAUTULLI_API_KEY}&cmd=get_history&length=50"
```

## What to look for

- Tautulli status errors connecting to Plex.
- Active streams stuck buffering or transcoding unexpectedly.
- Recent history gaps after Plex or library refresh incidents.
- Library stats that disagree with Plex `/library/sections`.
- Notification errors that explain missed alerts.

## Investigation flow

- Start with `status` and `get_server_info`.
- Use `get_activity` for current playback issues and `get_history` for
  timeline questions.
- Cross-check with the Plex skill for raw Plex server responses.
- Report the affected user/session/library and whether the issue is Tautulli,
  Plex, or downstream media storage.
