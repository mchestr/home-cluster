provider "authentik" {
  url   = "https://outpost.auth-system.svc.cluster.local"
  token = var.authentik_token
}
