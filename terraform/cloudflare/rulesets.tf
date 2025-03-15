resource "cloudflare_ruleset" "chestr-dev-rulesets" {
  name        = "domain rulesets"
  kind        = "zone"
  phase       = "http_request_firewall_custom"
  description = "chestr.dev rulesets"
  zone_id     = data.cloudflare_zone.domain.zone_id
  rules = [
    {
      expression  = "(cf.client.bot) or (cf.threat_score gt 14)"
      action      = "block"
      description = "Block known cloudflare bots"
      enabled     = true
    },
    {
      expression  = "(not ip.geoip.country in {\"CA\" \"US\" \"CN\"})"
      action      = "block"
      description = "Block all countries except CA,US,CN"
      enabled     = true
    }
  ]
}
