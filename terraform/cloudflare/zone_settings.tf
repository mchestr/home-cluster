resource "cloudflare_zone_setting" "always_use_https" {
  zone_id = data.cloudflare_zone.domain.zone_id
  setting_id = "always_use_https"
  value = "on"
}
