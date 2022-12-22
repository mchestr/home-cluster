#!/bin/bash

task snapshot:restore RSRC=vaultwarden CLAIM=vaultwarden-config-v1
task snapshot:restore RSRC=appdaemon CLAIM=appdaemon-config-v1 NAMESPACE=home
task snapshot:restore RSRC=esphome CLAIM=esphome-config-v1 NAMESPACE=home
task snapshot:restore RSRC=home-assistant CLAIM=home-assistant-config-v1 NAMESPACE=home
task snapshot:restore RSRC=radicale CLAIM=radicale-data-v1 NAMESPACE=home
task snapshot:restore RSRC=unifi CLAIM=unifi-data-v1 NAMESPACE=home
task snapshot:restore RSRC=zigbee2mqtt CLAIM=zigbee2mqtt-config-v1 NAMESPACE=home
task snapshot:restore RSRC=zwavejs2mqtt CLAIM=zwavejs2mqtt-config-v1 NAMESPACE=home
task snapshot:restore RSRC=bazarr CLAIM=bazarr-config-v1 NAMESPACE=media
task snapshot:restore RSRC=lidarr CLAIM=lidarr-config-v1 NAMESPACE=media
task snapshot:restore RSRC=overseerr CLAIM=overseerr-config-v1 NAMESPACE=media
task snapshot:restore RSRC=plex CLAIM=plex-config-v1 NAMESPACE=media
task snapshot:restore RSRC=prowlarr CLAIM=prowlarr-config-v1 NAMESPACE=media
task snapshot:restore RSRC=qbittorrent CLAIM=qbittorrent-config-v1 NAMESPACE=media
task snapshot:restore RSRC=radarr-4k CLAIM=radarr-4k-config-v1 NAMESPACE=media
task snapshot:restore RSRC=radarr CLAIM=radarr-config-v1 NAMESPACE=media
task snapshot:restore RSRC=sabnzbd CLAIM=sabnzbd-config-v1 NAMESPACE=media
task snapshot:restore RSRC=sonarr CLAIM=sonarr-config-v1 NAMESPACE=media
task snapshot:restore RSRC=tautulli CLAIM=tautulli-config-v1 NAMESPACE=media
task snapshot:restore RSRC=uptime-kuma CLAIM=uptime-kuma-config-v1 NAMESPACE=monitoring
