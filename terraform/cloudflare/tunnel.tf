resource "cloudflare_tunnel" "k8s" {
  account_id = var.cloudflared_tunnel_account_id
  name       = "k8s"
  secret     = var.cloudflared_tunnel_secret
}

resource "cloudflare_record" "status" {
  zone_id = data.cloudflare_zone.domain.id
  name    = "ingress"
  value   = "${cloudflare_tunnel.k8s.id}.cfargotunnel.com"
  type    = "CNAME"
  proxied = true
}
