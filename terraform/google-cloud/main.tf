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
        version = "4.64.0"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "4.5.0"
    }
    random = {
        source = "hashicorp/random"
        version = "3.5.1"
    }
  }

}

provider "google" {
  project     = var.project_id
  region      = "us-west1"
  zone        = "us-west1-b"
  credentials = var.google_cloud_credentials
}

provider "cloudflare" {
  api_token   = var.cloudflare_api_token
}
