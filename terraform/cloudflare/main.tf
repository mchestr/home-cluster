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
      version = "4.20.0"
    }
    onepassword = {
      source = "1Password/onepassword"
      version = "1.3.1"
    }
  }
}

provider "cloudflare" {
  api_token   = var.cloudflare_api_token
}

provider "onepassword" {
  token = var.onepassword_token
  url = var.onepassword_url
}

data "cloudflare_zone" "domain" {
  name = var.cluster_domain
}
