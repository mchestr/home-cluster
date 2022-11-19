provider "authentik" {
  url   = format("https://outpost.%s", var.cluster_domain)
  token = var.authentik_token
}
