#!/bin/bash

task volsync:restore RSRC=bazarr CLAIM=bazarr-config-v1 &
task volsync:restore RSRC=lidarr CLAIM=lidarr-config-v1 &
task volsync:restore RSRC=overseerr CLAIM=overseerr-config-v1 &
task volsync:restore RSRC=plex CLAIM=plex-config-v1 &
task volsync:restore RSRC=prowlarr CLAIM=prowlarr-config-v1 &
task volsync:restore RSRC=qbittorrent CLAIM=qbittorrent-config-v1 &
task volsync:restore RSRC=radarr-4k CLAIM=radarr-4k-config-v1 &
task volsync:restore RSRC=radarr CLAIM=radarr-config-v1 &
task volsync:restore RSRC=sabnzbd CLAIM=sabnzbd-config-v1 &
task volsync:restore RSRC=sonarr CLAIM=sonarr-config-v1 &
task volsync:restore RSRC=tautulli CLAIM=tautulli-config-v1 &
task volsync:restore RSRC=uptime-kuma CLAIM=uptime-kuma-config-v1 &
