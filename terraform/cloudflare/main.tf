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
      version = "5.1.0"
    }
    onepassword = {
      source = "1Password/onepassword"
      version = "2.1.2"
    }
  }
}

provider "cloudflare" {
  api_token   = data.onepassword_item.cloudflare.section[0].field[index(data.onepassword_item.cloudflare.section[0].field.*.label, "CLOUDFLARE_TERRAFORM_TOKEN")].value
}

provider "onepassword" {
  account = var.onepassword_account_id
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
