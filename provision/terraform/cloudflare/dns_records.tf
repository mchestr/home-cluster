resource "cloudflare_record" "ipv4" {
  name    = "ipv4"
  zone_id = lookup(data.cloudflare_zones.domain.zones[0], "id")
  value   = chomp(data.http.ipv4.response_body)
  proxied = true
  type    = "A"
  ttl     = 1
}

resource "cloudflare_record" "root" {
  name    = var.cloudflare_domain
  zone_id = lookup(data.cloudflare_zones.domain.zones[0], "id")
  value   = "ipv4.${var.cloudflare_domain}"
  proxied = true
  type    = "CNAME"
  ttl     = 1
}

resource "cloudflare_record" "cluster_ipv4" {
  name    = "ipv4"
  zone_id = lookup(data.cloudflare_zones.cluster_domain.zones[0], "id")
  value   = chomp(data.http.ipv4.response_body)
  proxied = true
  type    = "A"
  ttl     = 1
}

resource "cloudflare_record" "cluster_root" {
  name    = var.cloudflare_cluster_domain
  zone_id = lookup(data.cloudflare_zones.cluster_domain.zones[0], "id")
  value   = "ipv4.${var.cloudflare_cluster_domain}"
  proxied = true
  type    = "CNAME"
  ttl     = 1
}
