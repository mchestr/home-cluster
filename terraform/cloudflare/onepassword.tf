data "onepassword_vault" "kubernetes" {
  name = "kubernetes"
}

data "onepassword_item" "cloudflare" {
  vault = data.onepassword_vault.kubernetes.uuid
  uuid  = "hzn74rgezmipdtxmqlx63x2hv4"
}

resource "onepassword_item" "cloudflare-tunnel" {
  vault    = data.onepassword_vault.kubernetes.uuid
  title    = "cloudflare-tunnel"
  category = "password"
  password = cloudflare_zero_trust_tunnel_cloudflared.home-cluster.id

  section {
    label = "secrets"

    field {
      label = "CLOUDFLARED_TUNNEL_ID"
      value = cloudflare_zero_trust_tunnel_cloudflared.home-cluster.id
    }

    field {
      label = "CLOUDFLARED_TUNNEL_SECRET"
      value = data.onepassword_item.cloudflare.section[0].field[index(data.onepassword_item.cloudflare.section[0].field.*.label, "CLOUDFLARE_HOME_CLUSTER_TUNNEL_SECRET")].value
      type  = "CONCEALED"
    }
  }
}
