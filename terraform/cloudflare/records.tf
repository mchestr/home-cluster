# Tunnel CNAME
resource "cloudflare_record" "status" {
  zone_id = data.cloudflare_zone.domain.id
  name    = "ingress"
  value   = "${cloudflare_tunnel.k8s.id}.cfargotunnel.com"
  type    = "CNAME"
  proxied = true
}

# Amazon SES Settings
resource "cloudflare_record" "aws_ses_cname1" {
  zone_id = data.cloudflare_zone.domain.id
  proxied = false
  type    = "CNAME"
  name    = "r6aoj7vhzjzzuitmxypnvzq5om27foyc._domainkey.chestr.dev"
  value   = "r6aoj7vhzjzzuitmxypnvzq5om27foyc.dkim.amazonses.com"
}
resource "cloudflare_record" "aws_ses_cname2" {
  zone_id = data.cloudflare_zone.domain.id
  proxied = false
  type    = "CNAME"
  name    = "6ajw3icev6dwsjdcxqyfsorhtxsndc5f._domainkey.chestr.dev"
  value   = "6ajw3icev6dwsjdcxqyfsorhtxsndc5f.dkim.amazonses.com"
}
resource "cloudflare_record" "aws_ses_cname3" {
  zone_id = data.cloudflare_zone.domain.id
  proxied = false
  type    = "CNAME"
  name    = "dclakzwyzjqdkygjisjvbscqf5zxjqln._domainkey.chestr.dev"
  value   = "dclakzwyzjqdkygjisjvbscqf5zxjqln.dkim.amazonses.com"
}
resource "cloudflare_record" "aws_ses_mx" {
  zone_id  = data.cloudflare_zone.domain.id
  proxied  = false
  type     = "MX"
  name     = "mail"
  value    = "feedback-smtp.us-west-2.amazonses.com"
  priority = 10
}
resource "cloudflare_record" "aws_ses_txt" {
  zone_id = data.cloudflare_zone.domain.id
  proxied = false
  type    = "TXT"
  name    = "mail"
  value   = "v=spf1 include:amazonses.com ~all"
}
