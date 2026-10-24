terraform {

  required_version = ">= 1.3.0"
  cloud {
    hostname     = "app.terraform.io"
    organization = "mchestr"

    workspaces {
      name = "cloudflare"
    }
  }

  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      # https://github.com/cloudflare/terraform-provider-cloudflare/issues/5363
      version = "5.28.1"
    }
    onepassword = {
      source  = "1Password/onepassword"
      version = "3.4.0"
    }
  }
}

data "cloudflare_zone" "zone" {
  for_each = toset(var.zones)
  filter = {
    name = each.value
  }
}

data "cloudflare_account" "mchestr" {
  filter = {
    name = "mchestr"
  }
}
