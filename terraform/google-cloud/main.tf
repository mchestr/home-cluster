terraform {

  required_version = ">= 1.3.0"
  cloud {
    hostname     = "app.terraform.io"
    organization = "mchestr"

    workspaces {
      name = "home-google-cloud"
    }
  }

  required_providers {
    google = {
        source = "hashicorp/google"
        version = "4.85.0"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "4.36.0"
    }
    random = {
        source = "hashicorp/random"
        version = "3.6.2"
    }
  }

}

provider "google" {
  project     = var.project_id
  region      = var.region
  zone        = var.zone
  credentials = var.google_cloud_credentials
}

provider "cloudflare" {
  api_token   = var.cloudflare_api_token
}
