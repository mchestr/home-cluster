
provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

provider "onepassword" {
  url   = var.onepassword_url
  token = var.onepassword_token
}
