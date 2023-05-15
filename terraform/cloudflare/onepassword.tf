data "onepassword_vault" "kubernetes" {
  name = "kubernetes"
}

resource "onepassword_item" "item" {
  vault    = data.onepassword_vault.kubernetes.uuid
  title    = "cloudflare-tunnel-id"
  category = "password"

  section {
    label = "secrets"

    field {
      label = "CLOUDFLARED_K8S_TUNNEL_ID"
      type  = "STRING"
      value = cloudflare_tunnel.k8s.id
    }
  }
}
