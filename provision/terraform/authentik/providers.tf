provider "authentik" {
  url   = "https://ak-outpost-authentik-embedded-outpost.auth-system.svc.cluster.local"
  token = var.authentik_token
}
