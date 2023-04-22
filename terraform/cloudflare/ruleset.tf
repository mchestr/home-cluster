resource "cloudflare_managed_headers" "remove_x_forward_for" {
  zone_id = lookup(data.cloudflare_zones.domain.zones[0], "id")

  managed_response_headers {
    id      = "remove_x-forwarded-for_header"
    enabled = true
  }
}

resource "cloudflare_managed_headers" "wordpress_0_remove_x_forward_for" {
  zone_id = lookup(data.cloudflare_zones.wordpress_0_domain.zones[0], "id")

  managed_response_headers {
    id      = "remove_x-forwarded-for_header"
    enabled = true
  }
}
