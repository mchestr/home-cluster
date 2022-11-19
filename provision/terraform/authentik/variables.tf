variable "authentik_token" {
  type        = string
  description = "Authentik Token"
  sensitive = true
}
variable "cluster_domain" {
  type        = string
  description = "Cluster Domain Name"
  sensitive = true
}
variable "bazarr_user" {
  type        = string
  description = "Basic Auth Bazarr User"
  sensitive = true
}
variable "bazarr_password" {
  type        = string
  description = "Basic Auth Bazarr User"
  sensitive = true
}
variable "emqx_user" {
  type        = string
  description = "Basic Auth EMQX User"
  sensitive = true
}
variable "emqx_password" {
  type        = string
  description = "Basic Auth EMQX User"
  sensitive = true
}
variable "lidarr_user" {
  type        = string
  description = "Basic Auth Lidarr User"
  sensitive = true
}
variable "lidarr_password" {
  type        = string
  description = "Basic Auth Lidarr User"
  sensitive = true
}
variable "prowlarr_user" {
  type        = string
  description = "Basic Auth Prowlarr User"
  sensitive = true
}
variable "prowlarr_password" {
  type        = string
  description = "Basic Auth Prowlarr User"
  sensitive = true
}
variable "qbittorrent_user" {
  type        = string
  description = "Basic Auth QBittorrent User"
  sensitive = true
}
variable "qbittorrent_password" {
  type        = string
  description = "Basic Auth QBittorrent User"
  sensitive = true
}
variable "radarr-4k_user" {
  type        = string
  description = "Basic Auth Radarr-4K User"
  sensitive = true
}
variable "radarr-4k_password" {
  type        = string
  description = "Basic Auth Radarr-4K User"
  sensitive = true
}
variable "radarr_user" {
  type        = string
  description = "Basic Auth Radarr User"
  sensitive = true
}
variable "radarr_password" {
  type        = string
  description = "Basic Auth Radarr User"
  sensitive = true
}
variable "sonarr_user" {
  type        = string
  description = "Basic Auth Sonarr User"
  sensitive = true
}
variable "sonarr_password" {
  type        = string
  description = "Basic Auth Sonarr User"
  sensitive = true
}
variable "sync_user" {
  type        = string
  description = "Basic Auth Sync User"
  sensitive = true
}
variable "sync_password" {
  type        = string
  description = "Basic Auth Sync User"
  sensitive = true
}
variable "plex_client_id" {
  type        = string
  description = "Plex Client ID"
  sensitive = true
}
variable "plex_token" {
  type        = string
  description = "Plex token"
  sensitive = true
}
variable "plex_server" {
  type        = string
  description = "Plex server ID"
  sensitive = true
}
variable "google_consumer_key" {
  type        = string
  description = "Google OAuth consumer key"
  sensitive = true
}
variable "google_consumer_secret" {
  type        = string
  description = "Google OAuth consumer secret"
  sensitive = true
}
variable "user1_email" {
  type        = string
  description = "User1 email"
  sensitive = true
}
variable "user1_name" {
  type        = string
  description = "User1 name"
  sensitive = true
}
variable "user1_username" {
  type        = string
  description = "User1 username"
  sensitive = true
}
variable "user2_email" {
  type        = string
  description = "User2 email"
  sensitive = true
}
variable "user2_name" {
  type        = string
  description = "User2 name"
  sensitive = true
}
variable "user2_username" {
  type        = string
  description = "User2 username"
  sensitive = true
}
variable "recaptcha_site_key" {
  type        = string
  description = "Google Recaptcha site key"
  sensitive = true
}
variable "recaptcha_secret_key" {
  type        = string
  description = "Google Recaptcha secret key"
  sensitive = true
}
variable "oauth2_settings" {
  type = string
  description = "OAuth2 provider settings in JSON format"
  sensitive = true
}
