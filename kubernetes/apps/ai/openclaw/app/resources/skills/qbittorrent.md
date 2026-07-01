---
name: qbittorrent
description: Inspect the qBittorrent Web API during download investigations, especially torrents, transfer stats, categories, trackers, and stalled imports
metadata:
  { "openclaw": { "emoji": "torrent", "homepage": "https://github.com/qbittorrent/qBittorrent/wiki/WebUI-API-(qBittorrent-5.0)" } }
user-invocable: true
disable-model-invocation: false
---

Use this skill when an alert, log line, or user question points at qBittorrent,
especially stalled torrents, tracker failures, missing completed downloads,
cross-seed hooks, or Sonarr/Radarr import problems involving torrents.

Keep investigations read-only. Do not pause, resume, delete, recheck, or move
torrents unless explicitly told to remediate.

## Endpoint

In-cluster URL: `http://qbittorrent.media.svc.cluster.local:8080`

The cluster config whitelists in-cluster subnets for the Web API, so read-only
API calls from OpenClaw usually do not need a login cookie.

```sh
curl -fsS "http://qbittorrent.media.svc.cluster.local:8080/api/v2/app/version"
```

If auth is unexpectedly required, inspect the pod environment and qBittorrent
config through Kubernetes before trying credentials. Do not log in with a user
password unless explicitly told to.

## Fast checks

Version, preferences, and transfer info:

```sh
curl -fsS "http://qbittorrent.media.svc.cluster.local:8080/api/v2/app/version"
curl -fsS "http://qbittorrent.media.svc.cluster.local:8080/api/v2/app/preferences"
curl -fsS "http://qbittorrent.media.svc.cluster.local:8080/api/v2/transfer/info"
```

Torrent list, stalled torrents, and categories:

```sh
curl -fsS "http://qbittorrent.media.svc.cluster.local:8080/api/v2/torrents/info?filter=all"
curl -fsS "http://qbittorrent.media.svc.cluster.local:8080/api/v2/torrents/info?filter=stalled"
curl -fsS "http://qbittorrent.media.svc.cluster.local:8080/api/v2/torrents/categories"
```

Trackers for a specific torrent hash:

```sh
curl -fsS "http://qbittorrent.media.svc.cluster.local:8080/api/v2/torrents/trackers?hash=${TORRENT_HASH}"
```

Pipe responses through `jq` when available.

## What to look for

- Torrents stuck in stalled, error, missingFiles, or moving states.
- Save paths or categories that do not match `/data/downloads/torrents`.
- Tracker errors, unregistered torrents, or disabled categories.
- Low free space or transfer limits in app preferences/transfer info.
- Cross-seed category/hook issues after completion.

## Investigation flow

- Start with transfer info and stalled torrents.
- For a Sonarr/Radarr import issue, find the torrent category, save path, hash,
  and completion state.
- Check trackers for failed or unregistered torrents.
- Cross-check cross-seed logs when the category is `cross-seed`.
- Report the torrent name/hash, state, save path, tracker status, and safest
  next action.
