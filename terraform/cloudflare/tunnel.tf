resource "cloudflare_zero_trust_tunnel_cloudflared" "home-cluster" {
  account_id    = data.cloudflare_account.mchestr.account_id
  name          = "home-cluster"
  tunnel_secret = data.onepassword_item.cloudflare.section[0].field[index(data.onepassword_item.cloudflare.section[0].field.*.label, "CLOUDFLARE_HOME_CLUSTER_TUNNEL_SECRET")].value
  config_src     = "local"
}
