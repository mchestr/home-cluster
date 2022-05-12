resource "authentik_user" "user1" {
  username = data.sops_file.authentik_secrets.data["user1_username"]
  name     = data.sops_file.authentik_secrets.data["user1_name"]
  email    = data.sops_file.authentik_secrets.data["user1_email"]
  groups = [
    authentik_group.system-admins.id,
    authentik_group.grafana-admins.id,
    authentik_group.paperless-users.id,
    data.authentik_group.admins.id
  ]
}

resource "authentik_user" "user2" {
  username = data.sops_file.authentik_secrets.data["user2_username"]
  name     = data.sops_file.authentik_secrets.data["user2_name"]
  email    = data.sops_file.authentik_secrets.data["user2_email"]
  groups = [
    authentik_group.media-users.id,
    authentik_group.paperless-users.id
  ]
}

resource "authentik_source_oauth" "google" {
  name                = "Login with Google"
  slug                = "google"
  authentication_flow = data.authentik_flow.default-authentication.id
  enrollment_flow     = data.authentik_flow.default-enrollment.id

  provider_type   = "google"
  consumer_key    = data.sops_file.authentik_secrets.data["google_consumer_key"]
  consumer_secret = data.sops_file.authentik_secrets.data["google_consumer_secret"]
}

resource "authentik_source_plex" "name" {
  name                = "Login with Plex"
  slug                = "plex"
  authentication_flow = data.authentik_flow.default-authentication.id
  enrollment_flow     = data.authentik_flow.default-enrollment.id
  client_id           = data.sops_file.authentik_secrets.data["plex_client_id"]
  plex_token          = data.sops_file.authentik_secrets.data["plex_token"]
  allowed_servers = [
    data.sops_file.authentik_secrets.data["plex_server"]
  ]
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

resource "authentik_group" "paperless-users" {
  name = "paperless-users"
}

resource "authentik_group" "grafana-admins" {
  name = "grafana-admins"
}

resource "authentik_group" "grafana-editors" {
  name = "grafana-editors"
}
