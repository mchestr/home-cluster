# The same country allowlist on every zone served through the tunnel.
resource "cloudflare_ruleset" "firewall" {
  for_each    = data.cloudflare_zone.zone
  name        = "domain rulesets"
  kind        = "zone"
  phase       = "http_request_firewall_custom"
  description = "${each.key} rulesets"
  zone_id     = each.value.zone_id
  rules = [
    {
      # Mail providers post the RFC 8058 one-click unsubscribe from their own servers,
      # which can sit outside CA and US and fail the browser checks.
      expression = "(http.host eq \"my.mikeflix.lol\" and http.request.uri.path in {\"/api/email/unsubscribe\" \"/email/unsubscribe\"})"
      action     = "skip"
      action_parameters = {
        ruleset  = "current"
        products = ["bic", "securityLevel"]
      }
      description = "subs: let mail providers and members reach the unsubscribe link"
      enabled     = true
    },
    {
      expression  = "(not ip.geoip.country in {\"CA\" \"US\"})"
      action      = "block"
      description = "Block all countries except CA,US"
      enabled     = true
    }
  ]
}

moved {
  from = cloudflare_ruleset.chestr-dev-rulesets
  to   = cloudflare_ruleset.firewall["chestr.dev"]
}

resource "cloudflare_ruleset" "chestr-dev-config-settings" {
  name        = "configuration rules"
  kind        = "zone"
  phase       = "http_config_settings"
  description = "chestr.dev configuration rules"
  zone_id     = data.cloudflare_zone.zone["chestr.dev"].zone_id
  rules = [
    {
      # Waitlist pins its pages' scripts with CSP hashes; email obfuscation rewrites the HTML.
      expression = "(http.host in {\"waitlist.chestr.dev\" \"waitlist-checkout.chestr.dev\"})"
      action     = "set_config"
      action_parameters = {
        email_obfuscation = false
      }
      description = "Waitlist: leave the HTML alone"
      enabled     = true
    }
  ]
}
