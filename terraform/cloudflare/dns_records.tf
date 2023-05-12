resource "cloudflare_record" "ipv4" {
  name    = "ingress"
  zone_id = lookup(data.cloudflare_zones.domain.zones[0], "id")
  value   = chomp(data.http.ipv4.response_body)
  proxied = true
  type    = "A"
  ttl     = 1
}

resource "cloudflare_record" "root" {
  name    = "chestr.dev"
  zone_id = lookup(data.cloudflare_zones.domain.zones[0], "id")
  value   = "ingress.${var.cloudflare_domain}"
  proxied = true
  type    = "CNAME"
  ttl     = 1
}

resource "cloudflare_record" "wordpress-ipv4" {
  name    = "ingress"
  zone_id = lookup(data.cloudflare_zones.wordpress_0_domain.zones[0], "id")
  value   = chomp(data.http.ipv4.response_body)
  proxied = true
  type    = "A"
  ttl     = 1
}

resource "cloudflare_record" "wordpress-0-root" {
  name    = "stephk.co"
  zone_id = lookup(data.cloudflare_zones.wordpress_0_domain.zones[0], "id")
  value   = "ingress.${var.wordpress_0_domain}"
  proxied = true
  type    = "CNAME"
  ttl     = 1
}

# Amazon SES Settings
resource "cloudflare_record" "aws_ses_cname1" {
  zone_id = lookup(data.cloudflare_zones.domain.zones[0], "id")
  proxied = false
  type    = "CNAME"
  name    = var.aws_ses_cname1
  value   = var.aws_ses_cname1_value
}
resource "cloudflare_record" "aws_ses_cname2" {
  zone_id = lookup(data.cloudflare_zones.domain.zones[0], "id")
  proxied = false
  type    = "CNAME"
  name    = var.aws_ses_cname2
  value   = var.aws_ses_cname2_value
}
resource "cloudflare_record" "aws_ses_cname3" {
  zone_id = lookup(data.cloudflare_zones.domain.zones[0], "id")
  proxied = false
  type    = "CNAME"
  name    = var.aws_ses_cname3
  value   = var.aws_ses_cname3_value
}
resource "cloudflare_record" "aws_ses_mx" {
  zone_id  = lookup(data.cloudflare_zones.domain.zones[0], "id")
  proxied  = false
  type     = "MX"
  name     = "mail"
  value    = "feedback-smtp.us-west-2.amazonses.com"
  priority = 10
}
resource "cloudflare_record" "aws_ses_txt" {
  zone_id = lookup(data.cloudflare_zones.domain.zones[0], "id")
  proxied = false
  type    = "TXT"
  name    = "mail"
  value   = "v=spf1 include:amazonses.com ~all"
}
