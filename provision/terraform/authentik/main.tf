terraform {

  required_providers {
    authentik = {
      source  = "goauthentik/authentik"
      version = "2022.4.1"
    }
    sops = {
      source  = "carlpett/sops"
      version = "0.7.0"
    }
  }
}

data "sops_file" "authentik_secrets" {
  source_file = "secret.sops.yaml"
}

provider "authentik" {
  url   = data.sops_file.authentik_secrets.data["authentik_url"]
  token = data.sops_file.authentik_secrets.data["authentik_token"]
}

data "authentik_flow" "default-authorization-flow" {
  slug = "default-provider-authorization-implicit-consent"
}

data "authentik_flow" "default-authentication-flow" {
  slug = "default-source-authentication"
}

data "authentik_flow" "default-enrollment-flow" {
  slug = "default-source-enrollment"
}

data "authentik_group" "admins" {
  name = "authentik Admins"
}

resource "authentik_group" "system-admins" {
  name = "system-admins"
  attributes = jsonencode({
    bazarr_user          = data.sops_file.authentik_secrets.data["bazarr_user"],
    bazarr_password      = data.sops_file.authentik_secrets.data["bazarr_password"],
    emqx_user            = data.sops_file.authentik_secrets.data["emqx_user"],
    emqx_password        = data.sops_file.authentik_secrets.data["emqx_password"],
    k10_user             = data.sops_file.authentik_secrets.data["k10_user"],
    k10_password         = data.sops_file.authentik_secrets.data["k10_password"],
    lidarr_user          = data.sops_file.authentik_secrets.data["lidarr_user"],
    lidarr_password      = data.sops_file.authentik_secrets.data["lidarr_password"],
    nzbget_user          = data.sops_file.authentik_secrets.data["nzbget_control_user"],
    nzbget_password      = data.sops_file.authentik_secrets.data["nzbget_control_password"],
    prowlarr_user        = data.sops_file.authentik_secrets.data["prowlarr_user"],
    prowlarr_password    = data.sops_file.authentik_secrets.data["prowlarr_password"],
    qbittorrent_user     = data.sops_file.authentik_secrets.data["qbittorrent_user"],
    qbittorrent_password = data.sops_file.authentik_secrets.data["qbittorrent_password"],
    radarr-4k_user       = data.sops_file.authentik_secrets.data["radarr-4k_user"],
    radarr-4k_password   = data.sops_file.authentik_secrets.data["radarr-4k_password"],
    radarr_user          = data.sops_file.authentik_secrets.data["radarr_user"],
    radarr_password      = data.sops_file.authentik_secrets.data["radarr_password"],
    readarr_user         = data.sops_file.authentik_secrets.data["readarr_user"],
    readarr_password     = data.sops_file.authentik_secrets.data["readarr_password"],
    sonarr_user          = data.sops_file.authentik_secrets.data["sonarr_user"],
    sonarr_password      = data.sops_file.authentik_secrets.data["sonarr_password"],
  })
}

resource "authentik_group" "media-users" {
  name = "media-users"
  attributes = jsonencode({
    bazarr_user          = data.sops_file.authentik_secrets.data["bazarr_user"],
    bazarr_password      = data.sops_file.authentik_secrets.data["bazarr_password"],
    nzbget_user          = data.sops_file.authentik_secrets.data["nzbget_restricted_user"],
    nzbget_password      = data.sops_file.authentik_secrets.data["nzbget_restricted_password"],
    qbittorrent_user     = data.sops_file.authentik_secrets.data["qbittorrent_user"],
    qbittorrent_password = data.sops_file.authentik_secrets.data["qbittorrent_password"],
    radarr-4k_user       = data.sops_file.authentik_secrets.data["radarr-4k_user"],
    radarr-4k_password   = data.sops_file.authentik_secrets.data["radarr-4k_password"],
    radarr_user          = data.sops_file.authentik_secrets.data["radarr_user"],
    radarr_password      = data.sops_file.authentik_secrets.data["radarr_password"],
    readarr_user         = data.sops_file.authentik_secrets.data["readarr_user"],
    readarr_password     = data.sops_file.authentik_secrets.data["readarr_password"],
    sonarr_user          = data.sops_file.authentik_secrets.data["sonarr_user"],
    sonarr_password      = data.sops_file.authentik_secrets.data["sonarr_password"],
  })
}

resource "authentik_group" "grafana-admins" {
  name = "grafana-admins"
}

resource "authentik_group" "grafana-editors" {
  name = "grafana-editors"
}

locals {
  apps = {
    "zwavejs2mqtt"        = { group = "Home" }
    "zigbee2mqtt"         = { group = "Home" }
    "traefik"             = { group = "System" }
    "tautulli"            = { group = "Media" }
    "sonarr"              = { group = "Media", basic_auth_enabled = true }
    "readarr"             = { group = "Media", basic_auth_enabled = true }
    "radarr"              = { group = "Media", basic_auth_enabled = true }
    "radarr-4k"           = { group = "Media", basic_auth_enabled = true }
    "qbittorrent"         = { group = "Downloaders", basic_auth_enabled = true }
    "prowlarr"            = { group = "Media", basic_auth_enabled = true }
    "prometheus"          = { group = "System" }
    "paperless"           = { group = "Home" }
    "nzbget"              = { group = "Downloaders", basic_auth_enabled = true }
    "longhorn"            = { group = "System" }
    "lidarr"              = { group = "Media", basic_auth_enabled = true }
    "k10"                 = { group = "System", basic_auth_enabled = true, launch_url = format("https://k10.%s/k10/", data.sops_file.authentik_secrets.data["cluster_domain"]) }
    "home-assistant-code" = { group = "Editors" }
    "esphome"             = { group = "Home" }
    "emqx"                = { group = "System", basic_auth_enabled = true }
    "calibre-web"         = { group = "Home" }
    "calibre"             = { group = "System" }
    "cal"                 = { group = "System" }
    "bazarr"              = { group = "Media", basic_auth_enabled = true }
    "appdaemon"           = { group = "Home" }
    "appdaemon-code"      = { group = "Editors" }
    "alert-manager"       = { group = "System" }
  }
}

resource "authentik_provider_proxy" "providers" {
  for_each = local.apps

  name                          = format("%s proxy", each.key)
  external_host                 = format("https://%s.%s%s", each.key, data.sops_file.authentik_secrets.data["cluster_domain"], lookup(each.value, "external_host_path", ""))
  internal_host                 = lookup(each.value, "internal_host", "")
  authorization_flow            = data.authentik_flow.default-authorization-flow.id
  mode                          = lookup(each.value, "mode", "forward_single")
  basic_auth_enabled            = lookup(each.value, "basic_auth_enabled", false)
  basic_auth_password_attribute = format("%s_password", each.key)
  basic_auth_username_attribute = format("%s_user", each.key)
}

resource "authentik_application" "name" {
  for_each = local.apps

  name              = format("%s", each.key)
  slug              = format("%s", each.key)
  protocol_provider = authentik_provider_proxy.providers[each.key].id
  meta_icon         = format("https://home.%s/assets/data/%s/android-chrome-maskable-512x512.png", data.sops_file.authentik_secrets.data["cluster_domain"], each.key)
  meta_launch_url   = lookup(each.value, "launch_url", "")
  group             = lookup(each.value, "group", "")
}

resource "authentik_user" "user1" {
  username = data.sops_file.authentik_secrets.data["user1_username"]
  name     = data.sops_file.authentik_secrets.data["user1_name"]
  email    = data.sops_file.authentik_secrets.data["user1_email"]
  groups   = [authentik_group.system-admins.id, authentik_group.grafana-admins.id, data.authentik_group.admins.id]
}

resource "authentik_user" "user2" {
  username = data.sops_file.authentik_secrets.data["user2_username"]
  name     = data.sops_file.authentik_secrets.data["user2_name"]
  email    = data.sops_file.authentik_secrets.data["user2_email"]
  groups   = [authentik_group.media-users.id]
}
