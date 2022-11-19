resource "authentik_user" "user1" {
  username = var.user1_username
  name     = var.user1_name
  email    = var.user1_email
  groups = [
    authentik_group.system-admins.id,
    authentik_group.grafana-admins.id,
    data.authentik_group.admins.id,
    authentik_group.home-users.id
  ]
}

resource "authentik_user" "user2" {
  username = var.user2_username
  name     = var.user2_name
  email    = var.user2_email
  groups = [
    authentik_group.media-users.id,
    authentik_group.home-users.id
  ]
}

resource "authentik_source_oauth" "google" {
  name                = "Login with Google"
  slug                = "google"
  authentication_flow = data.authentik_flow.default-authentication.id
  enrollment_flow     = data.authentik_flow.default-enrollment.id

  provider_type   = "google"
  consumer_key    = var.google_consumer_key
  consumer_secret = var.google_consumer_secret
}

resource "authentik_source_plex" "name" {
  name                = "Login with Plex"
  slug                = "plex"
  authentication_flow = data.authentik_flow.default-authentication.id
  enrollment_flow     = data.authentik_flow.default-enrollment.id
  client_id           = var.plex_client_id
  plex_token          = var.plex_token
  allowed_servers = [
    var.plex_server
  ]
}

data "authentik_group" "admins" {
  name = "authentik Admins"
}

resource "authentik_group" "system-admins" {
  name = "system-admins"
  attributes = jsonencode({
    bazarr_user          = var.bazarr_user
    bazarr_password      = var.bazarr_password
    emqx_user            = var.emqx_user
    emqx_password        = var.emqx_password
    lidarr_user          = var.lidarr_user
    lidarr_password      = var.lidarr_password
    prowlarr_user        = var.prowlarr_user
    prowlarr_password    = var.prowlarr_password
    qbittorrent_user     = var.qbittorrent_user
    qbittorrent_password = var.qbittorrent_password
    radarr-4k_user       = var.radarr-4k_user
    radarr-4k_password   = var.radarr-4k_password
    radarr_user          = var.radarr_user
    radarr_password      = var.radarr_password
    sonarr_user          = var.sonarr_user
    sonarr_password      = var.sonarr_password
    sync_user            = var.sync_user
    sync_password        = var.sync_password
  })
}

resource "authentik_group" "media-users" {
  name = "media-users"
  attributes = jsonencode({
    bazarr_user          = var.bazarr_user
    bazarr_password      = var.bazarr_password
    qbittorrent_user     = var.qbittorrent_user
    qbittorrent_password = var.qbittorrent_password
    radarr-4k_user       = var.radarr-4k_user
    radarr-4k_password   = var.radarr-4k_password
    radarr_user          = var.radarr_user
    radarr_password      = var.radarr_password
    sonarr_user          = var.sonarr_user
    sonarr_password      = var.sonarr_password
  })
}

resource "authentik_group" "home-users" {
  name = "home-users"
}

resource "authentik_group" "grafana-admins" {
  name = "grafana-admins"
}

resource "authentik_group" "grafana-editors" {
  name = "grafana-editors"
}
