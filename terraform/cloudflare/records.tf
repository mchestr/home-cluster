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
  name    = var.aws_ses_cname1
  value   = var.aws_ses_cname1_value
}
resource "cloudflare_record" "aws_ses_cname2" {
  zone_id = data.cloudflare_zone.domain.id
  proxied = false
  type    = "CNAME"
  name    = var.aws_ses_cname2
  value   = var.aws_ses_cname2_value
}
resource "cloudflare_record" "aws_ses_cname3" {
  zone_id = data.cloudflare_zone.domain.id
  proxied = false
  type    = "CNAME"
  name    = var.aws_ses_cname3
  value   = var.aws_ses_cname3_value
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
