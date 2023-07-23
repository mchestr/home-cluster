# Single Redirects resource
resource "cloudflare_ruleset" "redirect_overseerr" {
  zone_id     = data.cloudflare_zone.domain.id
  name        = "redirects"
  description = "Redirects ruleset"
  kind        = "zone"
  phase       = "http_request_dynamic_redirect"

  rules {
    action = "redirect"
    action_parameters {
      from_value {
        status_code = 301
        target_url {
          value = "https://requests.chestr.dev"
        }
        preserve_query_string = false
      }
    }
    expression  = "(http.host eq \"overseerr.chestr.dev\")"
    description = "Redirect visitors still using old URL"
    enabled     = true
  }
}
