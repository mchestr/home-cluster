resource "cloudflare_ruleset" "transform_remove_x_forward_for" {
  zone_id = lookup(data.cloudflare_zones.domain.zones[0], "id")
  name    = "Remove X-Forwarded-For Header"
  kind    = "zone"
  phase   = "http_request_late_transform"
  rules {
    action = "rewrite"
    action_parameters {
      headers {
        name      = "X-Forwarded-For"
        operation = "remove"
      }
    }
    enabled    = true
    expression = "true"
  }
}
