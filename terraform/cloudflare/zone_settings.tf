resource "cloudflare_zone_setting" "always_use_https" {
  zone_id = data.cloudflare_zone.domain.zone_id
  setting_id = "always_use_https"
  value = "on"
}
resource "cloudflare_zone_setting" "ssl" {
  zone_id = data.cloudflare_zone.domain.zone_id
  setting_id = "ssl"
  value = "strict"
}
resource "cloudflare_zone_setting" "min_tls_version" {
  zone_id = data.cloudflare_zone.domain.zone_id
  setting_id = "min_tls_version"
  value = "1.2"
}
resource "cloudflare_zone_setting" "opportunistic_encryption" {
  zone_id = data.cloudflare_zone.domain.zone_id
  setting_id = "opportunistic_encryption"
  value = "on"
}
resource "cloudflare_zone_setting" "tls_1_3" {
  zone_id = data.cloudflare_zone.domain.zone_id
  setting_id = "tls_1_3"
  value = "zrt"
}
resource "cloudflare_zone_setting" "automatic_https_rewrites" {
  zone_id = data.cloudflare_zone.domain.zone_id
  setting_id = "automatic_https_rewrites"
  value = "on"
}
resource "cloudflare_zone_setting" "browser_check" {
  zone_id = data.cloudflare_zone.domain.zone_id
  setting_id = "browser_check"
  value = "on"
}
resource "cloudflare_zone_setting" "challenge_ttl" {
  zone_id = data.cloudflare_zone.domain.zone_id
  setting_id = "challenge_ttl"
  value = 1800
}
resource "cloudflare_zone_setting" "privacy_pass" {
  zone_id = data.cloudflare_zone.domain.zone_id
  setting_id = "privacy_pass"
  value = "on"
}
resource "cloudflare_zone_setting" "security_level" {
  zone_id = data.cloudflare_zone.domain.zone_id
  setting_id = "security_level"
  value = "medium"
}
resource "cloudflare_zone_setting" "brotli" {
  zone_id = data.cloudflare_zone.domain.zone_id
  setting_id = "brotli"
  value = "on"
}
resource "cloudflare_zone_setting" "rocket_loader" {
  zone_id = data.cloudflare_zone.domain.zone_id
  setting_id = "rocket_loader"
  value = "on"
}
resource "cloudflare_zone_setting" "http3" {
  zone_id = data.cloudflare_zone.domain.zone_id
  setting_id = "http3"
  value = "on"
}
resource "cloudflare_zone_setting" "ipv6" {
  zone_id = data.cloudflare_zone.domain.zone_id
  setting_id = "ipv6"
  value = "on"
}
resource "cloudflare_zone_setting" "websockets" {
  zone_id = data.cloudflare_zone.domain.zone_id
  setting_id = "websockets"
  value = "on"
}
resource "cloudflare_zone_setting" "opportunistic_onion" {
  zone_id = data.cloudflare_zone.domain.zone_id
  setting_id = "opportunistic_onion"
  value = "on"
}
resource "cloudflare_zone_setting" "pseudo_ipv4" {
  zone_id = data.cloudflare_zone.domain.zone_id
  setting_id = "pseudo_ipv4"
  value = "off"
}
resource "cloudflare_zone_setting" "ip_geolocation" {
  zone_id = data.cloudflare_zone.domain.zone_id
  setting_id = "ip_geolocation"
  value = "on"
}
resource "cloudflare_zone_setting" "email_obfuscation" {
  zone_id = data.cloudflare_zone.domain.zone_id
  setting_id = "email_obfuscation"
  value = "on"
}
resource "cloudflare_zone_setting" "server_side_exclude" {
  zone_id = data.cloudflare_zone.domain.zone_id
  setting_id = "server_side_exclude"
  value = "on"
}
resource "cloudflare_zone_setting" "hotlink_protection" {
  zone_id = data.cloudflare_zone.domain.zone_id
  setting_id = "hotlink_protection"
  value = "on"
}
