variable "cloudflare_api_token" {
  type        = string
  description = "Cloudflare Account API Token"
}
variable "cloudflared_tunnel_secret" {
  type        = string
  description = "Cloudflared Tunnel Secret"
}
variable "onepassword_token" {
  type = string
  description = "OnePassword API Token"
}
variable "onepassword_url" {
  type = string
  description = "OnePassword Connect API URL"
  default = "http://localhost:8080"
}
variable "cluster_domain" {
  type = string
  description = "Cluster Domain Name"
  default = "chestr.dev"
}
