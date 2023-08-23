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
      version = "4.13.0"
    }
    onepassword = {
      source = "1Password/onepassword"
      version = "1.2.0"
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

data "cloudflare_zone" "wordpress_0_domain" {
  name = var.wordpress_0_domain
}
