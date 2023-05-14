variable "project_id" {
  type        = string
  description = "Google Project ID"
}
variable "cloudflare_api_token" {
  type        = string
  description = "Cloudflare Account API Token"
}
variable "google_cloud_credentials" {
  type = string
  description = "Google Cloud Credentials in JSON string format"
}
variable "cloudflared_tunnel_account_id" {
  type        = string
  description = "Cloudflared Tunnel Account ID"
}
variable "cloudflared_tunnel_secret" {
  type        = string
  description = "Cloudflared Tunnel Secret"
}
variable "domain" {
  type = string
  description = "Domain name"
  default = "chestr.dev"
}
variable "subdomain" {
  type = string
  description = "Subdomain of dashboard"
  default = "status"
}
variable "tag" {
  type = string
  description = "Uptime Kuma Tag"
  # renovate: datasource=github-releases depName=louislam/uptime-kuma
  default = "1.20.0-beta.0"
}
