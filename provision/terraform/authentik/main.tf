terraform {

  required_providers {
    authentik = {
      source  = "goauthentik/authentik"
      version = "2022.4.1"
    }
    sops = {
      source  = "carlpett/sops"
      version = "0.7.0"
    }
  }
}

data "sops_file" "authentik_secrets" {
  source_file = "secret.sops.yaml"
}

provider "authentik" {
  url   = data.sops_file.authentik_secrets.data["authentik_url"]
  token = data.sops_file.authentik_secrets.data["authentik_token"]
}
