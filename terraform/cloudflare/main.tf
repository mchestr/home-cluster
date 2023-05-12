terraform {

  required_version = ">= 1.3.0"
  cloud {
    hostname     = "app.terraform.io"
    organization = "mchestr"

    workspaces {
      name = "home-cloudflare"
    }
  }

  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "4.5.0"
    }
  }
}

provider "cloudflare" {
  api_token   = var.cloudflare_api_token
}

data "cloudflare_zone" "domain" {
  name = "chestr.dev"
}

data "cloudflare_zone" "wordpress_0_domain" {
  name = "stephk.co"
}
