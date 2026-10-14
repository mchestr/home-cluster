resource "cloudflare_ruleset" "chestr-dev-rulesets" {
  name        = "domain rulesets"
  kind        = "zone"
  phase       = "http_request_firewall_custom"
  description = "chestr.dev rulesets"
  zone_id     = data.cloudflare_zone.domain.zone_id
  rules = [
    # {
    #   expression  = "(cf.client.bot) or (cf.threat_score gt 14)"
    #   action      = "block"
    #   description = "Block known cloudflare bots"
    #   enabled     = true
    # },
    {
      expression  = "(not ip.geoip.country in {\"CA\" \"US\" \"CN\"})"
      action      = "block"
      description = "Block all countries except CA,US,CN"
      enabled     = true
    }
  ]
}

resource "cloudflare_ruleset" "chestr-dev-config-settings" {
  name        = "configuration rules"
  kind        = "zone"
  phase       = "http_config_settings"
  description = "chestr.dev configuration rules"
  zone_id     = data.cloudflare_zone.domain.zone_id
  rules = [
    {
      # Ferry Watch pins its pages' scripts with CSP hashes; Rocket Loader and email obfuscation rewrite the HTML.
      expression  = "(http.host in {\"ferry.chestr.dev\" \"ferry-checkout.chestr.dev\"})"
      action      = "set_config"
      action_parameters = {
        rocket_loader     = false
        email_obfuscation = false
      }
      description = "Ferry Watch: leave the HTML alone"
      enabled     = true
    }
  ]
}
