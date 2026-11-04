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

# Only public traffic reaches Cloudflare: LAN clients resolve the apex through UniFi DNS to Silo
# on envoy-internal. 308 keeps the method and body, but Stripe and Discord do not follow redirects.
resource "cloudflare_ruleset" "mikeflix-lol-redirects" {
  name        = "redirect rules"
  kind        = "zone"
  phase       = "http_request_dynamic_redirect"
  description = "mikeflix.lol redirect rules"
  zone_id     = data.cloudflare_zone.zone["mikeflix.lol"].zone_id
  rules = [
    {
      expression = "(http.host eq \"mikeflix.lol\")"
      action     = "redirect"
      action_parameters = {
        from_value = {
          status_code = 308
          target_url = {
            expression = "concat(\"https://my.mikeflix.lol\", http.request.uri.path)"
          }
          preserve_query_string = true
        }
      }
      description = "Public apex: send plex-manager links to my.mikeflix.lol"
      enabled     = true
    }
  ]
}
