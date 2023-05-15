resource "cloudflare_tunnel" "k8s" {
  account_id = cloudflare_account.mchestr.id
  name       = "k8s"
  secret     = var.cloudflared_tunnel_secret
}
