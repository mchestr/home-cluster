# One set of settings, applied to every zone in var.zones.
locals {
  zone_settings = {
    always_use_https         = "on"
    ssl                      = "strict"
    min_tls_version          = "1.2"
    opportunistic_encryption = "on"
    tls_1_3                  = "zrt"
    automatic_https_rewrites = "on"
    browser_check            = "on"
    challenge_ttl            = 1800
    privacy_pass             = "on"
    security_level           = "medium"
    brotli                   = "on"
    rocket_loader            = "on"
    http3                    = "on"
    ipv6                     = "on"
    websockets               = "on"
    opportunistic_onion      = "on"
    pseudo_ipv4              = "off"
    ip_geolocation           = "on"
    email_obfuscation        = "on"
    server_side_exclude      = "on"
    hotlink_protection       = "on"
    # The LAN DNS overrides only A records, so an ECH config from the HTTPS record
    # breaks TLS to envoy-external, which has no ECH key or cloudflare-ech.com cert
    ech                      = "off"
  }
  zone_setting_pairs = {
    for pair in setproduct(var.zones, keys(local.zone_settings)) :
    "${pair[0]}/${pair[1]}" => { zone = pair[0], setting = pair[1] }
  }
}

resource "cloudflare_zone_setting" "this" {
  for_each   = local.zone_setting_pairs
  zone_id    = data.cloudflare_zone.zone[each.value.zone].zone_id
  setting_id = each.value.setting
  value      = local.zone_settings[each.value.setting]
}

moved {
  from = cloudflare_zone_setting.always_use_https
  to   = cloudflare_zone_setting.this["chestr.dev/always_use_https"]
}

moved {
  from = cloudflare_zone_setting.ssl
  to   = cloudflare_zone_setting.this["chestr.dev/ssl"]
}

moved {
  from = cloudflare_zone_setting.min_tls_version
  to   = cloudflare_zone_setting.this["chestr.dev/min_tls_version"]
}

moved {
  from = cloudflare_zone_setting.opportunistic_encryption
  to   = cloudflare_zone_setting.this["chestr.dev/opportunistic_encryption"]
}

moved {
  from = cloudflare_zone_setting.tls_1_3
  to   = cloudflare_zone_setting.this["chestr.dev/tls_1_3"]
}

moved {
  from = cloudflare_zone_setting.automatic_https_rewrites
  to   = cloudflare_zone_setting.this["chestr.dev/automatic_https_rewrites"]
}

moved {
  from = cloudflare_zone_setting.browser_check
  to   = cloudflare_zone_setting.this["chestr.dev/browser_check"]
}

moved {
  from = cloudflare_zone_setting.challenge_ttl
  to   = cloudflare_zone_setting.this["chestr.dev/challenge_ttl"]
}

moved {
  from = cloudflare_zone_setting.privacy_pass
  to   = cloudflare_zone_setting.this["chestr.dev/privacy_pass"]
}

moved {
  from = cloudflare_zone_setting.security_level
  to   = cloudflare_zone_setting.this["chestr.dev/security_level"]
}

moved {
  from = cloudflare_zone_setting.brotli
  to   = cloudflare_zone_setting.this["chestr.dev/brotli"]
}

moved {
  from = cloudflare_zone_setting.rocket_loader
  to   = cloudflare_zone_setting.this["chestr.dev/rocket_loader"]
}

moved {
  from = cloudflare_zone_setting.http3
  to   = cloudflare_zone_setting.this["chestr.dev/http3"]
}

moved {
  from = cloudflare_zone_setting.ipv6
  to   = cloudflare_zone_setting.this["chestr.dev/ipv6"]
}

moved {
  from = cloudflare_zone_setting.websockets
  to   = cloudflare_zone_setting.this["chestr.dev/websockets"]
}

moved {
  from = cloudflare_zone_setting.opportunistic_onion
  to   = cloudflare_zone_setting.this["chestr.dev/opportunistic_onion"]
}

moved {
  from = cloudflare_zone_setting.pseudo_ipv4
  to   = cloudflare_zone_setting.this["chestr.dev/pseudo_ipv4"]
}

moved {
  from = cloudflare_zone_setting.ip_geolocation
  to   = cloudflare_zone_setting.this["chestr.dev/ip_geolocation"]
}

moved {
  from = cloudflare_zone_setting.email_obfuscation
  to   = cloudflare_zone_setting.this["chestr.dev/email_obfuscation"]
}

moved {
  from = cloudflare_zone_setting.server_side_exclude
  to   = cloudflare_zone_setting.this["chestr.dev/server_side_exclude"]
}

moved {
  from = cloudflare_zone_setting.hotlink_protection
  to   = cloudflare_zone_setting.this["chestr.dev/hotlink_protection"]
}
