#!/bin/bash

task volsync:restore RSRC=vaultwarden CLAIM=vaultwarden-config-v1
task volsync:restore RSRC=appdaemon CLAIM=appdaemon-config-v1
task volsync:restore RSRC=esphome CLAIM=esphome-config-v1
task volsync:restore RSRC=zigbee2mqtt CLAIM=zigbee2mqtt-config-v1
task volsync:restore RSRC=radicale CLAIM=radicale-data-v1
task volsync:restore RSRC=unifi CLAIM=unifi-data-v1
task volsync:restore RSRC=bazarr CLAIM=bazarr-config-v1 NAMESPACE=media
task volsync:restore RSRC=lidarr CLAIM=lidarr-config-v1 NAMESPACE=media
task volsync:restore RSRC=overseerr CLAIM=overseerr-config-v1 NAMESPACE=media
task volsync:restore RSRC=plex CLAIM=plex-config-v1 NAMESPACE=media
task volsync:restore RSRC=prowlarr CLAIM=prowlarr-config-v1 NAMESPACE=media
task volsync:restore RSRC=qbittorrent CLAIM=qbittorrent-config-v1 NAMESPACE=media
task volsync:restore RSRC=radarr-4k CLAIM=radarr-4k-config-v1 NAMESPACE=media
task volsync:restore RSRC=radarr CLAIM=radarr-config-v1 NAMESPACE=media
task volsync:restore RSRC=sabnzbd CLAIM=sabnzbd-config-v1 NAMESPACE=media
task volsync:restore RSRC=sonarr CLAIM=sonarr-config-v1 NAMESPACE=media
task volsync:restore RSRC=tautulli CLAIM=tautulli-config-v1 NAMESPACE=media
task volsync:restore RSRC=uptime-kuma CLAIM=uptime-kuma-config-v1 NAMESPACE=monitoring
