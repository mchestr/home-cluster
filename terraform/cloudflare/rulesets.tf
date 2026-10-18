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
      # Waitlist pins its pages' scripts with CSP hashes; Rocket Loader and email obfuscation rewrite the HTML.
      expression = "(http.host in {\"waitlist.chestr.dev\" \"waitlist-checkout.chestr.dev\"})"
      action     = "set_config"
      action_parameters = {
        rocket_loader     = false
        email_obfuscation = false
      }
      description = "Waitlist: leave the HTML alone"
      enabled     = true
    }
  ]
}
