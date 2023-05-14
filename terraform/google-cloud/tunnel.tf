resource "cloudflare_tunnel" "uptime-kuma" {
  account_id = var.cloudflared_tunnel_account_id
  name       = "uptime-kuma"
  secret     = var.cloudflared_tunnel_secret
}

resource "cloudflare_tunnel_config" "uptime-kuma-config" {
  account_id = var.cloudflared_tunnel_account_id
  tunnel_id  = cloudflare_tunnel.uptime-kuma.id

  config {
    origin_request {
      connect_timeout          = "1m0s"
      tls_timeout              = "1m0s"
      tcp_keep_alive           = "1m0s"
      no_happy_eyeballs        = false
      keep_alive_connections   = 1024
      keep_alive_timeout       = "1m0s"
      origin_server_name       = "${var.subdomain}.${var.domain}"
    }
    ingress_rule {
      service = "http://localhost:3001"
    }
  }
}

data "cloudflare_zone" "domain" {
  name = var.domain
}

resource "cloudflare_record" "status" {
  zone_id = data.cloudflare_zone.domain.id
  name    = var.subdomain
  value   = "${cloudflare_tunnel.uptime-kuma.id}.cfargotunnel.com"
  type    = "CNAME"
  proxied = true
}
