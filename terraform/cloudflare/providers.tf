provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

provider "onepassword" {
  connect_url   = var.onepassword_url
  connect_token = var.onepassword_token
}
