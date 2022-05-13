locals {
  apps = {
    "zwavejs2mqtt"        = { group = "Home System" }
    "zigbee2mqtt"         = { group = "Home System" }
    "traefik"             = { group = "System" }
    "tautulli"            = { group = "Media" }
    "sonarr"              = { group = "Media", basic_auth_enabled = true }
    "readarr"             = { group = "Media", basic_auth_enabled = true }
    "radarr"              = { group = "Media", basic_auth_enabled = true }
    "radarr-4k"           = { group = "Media", basic_auth_enabled = true }
    "qbittorrent"         = { group = "Downloaders", basic_auth_enabled = true }
    "prowlarr"            = { group = "Media", basic_auth_enabled = true }
    "prometheus"          = { group = "System" }
    "paperless"           = { group = "Home" }
    "nzbget"              = { group = "Downloaders", basic_auth_enabled = true }
    "longhorn"            = { group = "System" }
    "lidarr"              = { group = "Media", basic_auth_enabled = true }
    "k10"                 = { group = "System", basic_auth_enabled = true, launch_url = format("https://k10.%s/k10/", data.sops_file.authentik_secrets.data["cluster_domain"]) }
    "home-assistant-code" = { group = "Editors" }
    "esphome"             = { group = "Home System" }
    "emqx"                = { group = "System", basic_auth_enabled = true }
    "dashboard"           = { group = "System" }
    "calibre-web"         = { group = "Home" }
    "calibre"             = { group = "System" }
    "cal"                 = { group = "System" }
    "bazarr"              = { group = "Media", basic_auth_enabled = true }
    "appdaemon"           = { group = "Home System" }
    "appdaemon-code"      = { group = "Editors" }
    "alert-manager"       = { group = "System" }
  }

  admin_apps = toset(compact(([
    for i, each in local.apps :
    contains(["System", "Editors", "Home System"], each.group) ? i : ""
  ])))

  media_apps = toset(compact(([
    for i, each in local.apps :
    contains(["Media"], each.group) ? i : ""
  ])))
}

resource "authentik_provider_proxy" "providers" {
  for_each = local.apps

  name                          = format("%s proxy", each.key)
  external_host                 = format("https://%s.%s%s", each.key, data.sops_file.authentik_secrets.data["cluster_domain"], lookup(each.value, "external_host_path", ""))
  internal_host                 = lookup(each.value, "internal_host", "")
  authorization_flow            = data.authentik_flow.default-authorization.id
  mode                          = lookup(each.value, "mode", "forward_single")
  basic_auth_enabled            = lookup(each.value, "basic_auth_enabled", false)
  basic_auth_password_attribute = format("%s_password", each.key)
  basic_auth_username_attribute = format("%s_user", each.key)
}

resource "authentik_application" "name" {
  for_each = local.apps

  name              = format("%s", each.key)
  slug              = format("%s", each.key)
  protocol_provider = authentik_provider_proxy.providers[each.key].id
  meta_icon         = format("https://home.%s/assets/data/%s/android-chrome-maskable-512x512.png", data.sops_file.authentik_secrets.data["cluster_domain"], each.key)
  meta_launch_url   = lookup(each.value, "launch_url", "")
  group             = lookup(each.value, "group", "")
}

resource "authentik_provider_oauth2" "grafana" {
  name               = "grafana"
  client_id          = data.sops_file.authentik_secrets.data["grafana_client_id"]
  client_secret      = data.sops_file.authentik_secrets.data["grafana_client_secret"]
  authorization_flow = data.authentik_flow.default-authorization.id
  signing_key        = data.authentik_certificate_key_pair.generated.id
  property_mappings  = data.authentik_scope_mapping.scopes.ids
  redirect_uris = [
    data.sops_file.authentik_secrets.data["grafana_redirect_uri"]
  ]
}

resource "authentik_application" "grafana" {
  name              = "grafana"
  slug              = "grafana"
  protocol_provider = authentik_provider_oauth2.grafana.id
  meta_icon         = format("https://home.%s/assets/data/grafana/android-chrome-maskable-512x512.png", data.sops_file.authentik_secrets.data["cluster_domain"])
  group             = "System"
}

resource "authentik_provider_oauth2" "wiki" {
  name               = "wiki"
  sub_mode           = "user_username"
  client_id          = data.sops_file.authentik_secrets.data["wikijs_client_id"]
  client_secret      = data.sops_file.authentik_secrets.data["wikijs_client_secret"]
  authorization_flow = data.authentik_flow.default-authorization.id
  signing_key        = data.authentik_certificate_key_pair.generated.id
  property_mappings  = data.authentik_scope_mapping.scopes.ids
  redirect_uris = [
    format("%s/callback", data.sops_file.authentik_secrets.data["wikijs_redirect_uri"])
  ]
}

resource "authentik_application" "wiki" {
  name              = "wiki"
  slug              = "wiki"
  protocol_provider = authentik_provider_oauth2.wiki.id
  meta_icon         = format("https://home.%s/assets/data/wikijs/android-chrome-maskable-512x512.png", data.sops_file.authentik_secrets.data["cluster_domain"])
  meta_launch_url   = data.sops_file.authentik_secrets.data["wikijs_redirect_uri"]
  group             = "System"
}
