resource "cloudflare_tunnel" "k8s" {
  account_id = var.cloudflared_tunnel_account_id
  name       = "k8s"
  secret     = var.cloudflared_tunnel_secret
}
