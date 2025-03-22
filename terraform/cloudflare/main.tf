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
      version = "5.2.0"
    }
    onepassword = {
      source  = "1Password/onepassword"
      version = "2.1.2"
    }
  }
}

data "cloudflare_zone" "domain" {
  filter = {
    name = var.cluster_domain
  }
}

data "cloudflare_account" "mchestr" {
  filter = {
    name = "mchestr"
  }
}
