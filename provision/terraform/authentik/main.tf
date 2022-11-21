terraform {

  required_version = ">= 1.3.0"
  cloud {
    hostname     = "app.terraform.io"
    organization = "mchestr"

    workspaces {
      name = "home-authentik"
    }
  }

  required_providers {
    authentik = {
      source  = "goauthentik/authentik"
      version = "2022.10.0"
    }
  }
}

locals {
  proxy_apps = {
    alert-manager       = {}
    appdaemon           = { group = "Home Automation" }
    appdaemon-code      = { group = "Code Editors" }
    bazarr              = { group = "Media", basic_auth_enabled = true }
    cal                 = {}
    dashboard           = {}
    emqx                = { basic_auth_enabled = true }
    esphome             = { group = "Home Automation" }
    home-assistant-code = { group = "Code Editors" }
    kopia               = {}
    lidarr              = { group = "Media", basic_auth_enabled = true }
    longhorn            = {}
    paperless           = { group = "Home" }
    prometheus          = {}
    prowlarr            = { group = "Media", basic_auth_enabled = true }
    qbittorrent         = { group = "Downloaders", basic_auth_enabled = true }
    radarr              = { group = "Media", basic_auth_enabled = true }
    radarr-4k           = { group = "Media", basic_auth_enabled = true }
    sabnzbd             = { group = "Downloaders" }
    sonarr              = { group = "Media", basic_auth_enabled = true }
    sync                = { group = "Home", basic_auth_enabled = true }
    tautulli            = { group = "Media" }
    thanos              = {}
    traefik             = {}
    zigbee2mqtt         = { group = "Home Automation" }
    zwavejs2mqtt        = { group = "Home Automation" }
  }

  oauth2_settings_decoded = jsondecode(var.oauth2_settings)

  oauth2_apps = {
    grafana = {}
    minio   = { extra_scopes = [authentik_scope_mapping.oidc-scope-minio.id] }
    outline = {}
    immich  = {}
  }

  ldap_apps = {
  }

  media_apps = {
    for k, v in authentik_application.name : k => v if contains(["Media", "Downloaders"], v.group)
  }
  home_apps = {
    for k, v in authentik_application.name : k => v if contains(["Home"], v.group)
  }
}
