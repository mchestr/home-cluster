resource "authentik_service_connection_kubernetes" "local" {
  name  = "Local Kubernetes Cluster"
  local = true
}

resource "authentik_outpost" "outpost" {
  name = "authentik Embedded Outpost"
  type = "proxy"
  protocol_providers = [
    for app in authentik_provider_proxy.providers : app.id
  ]
  service_connection = authentik_service_connection_kubernetes.local.id
  config = jsonencode({
    log_level                      = "debug",
    docker_labels                  = null,
    authentik_host                 = format("https://outpost.%s", var.cluster_domain),
    docker_network                 = null,
    container_image                = null,
    docker_map_ports               = true,
    kubernetes_replicas            = 1,
    kubernetes_namespace           = "auth-system",
    authentik_host_browser         = "",
    object_naming_template         = "ak-outpost-%(name)s",
    authentik_host_insecure        = false,
    kubernetes_service_type        = "ClusterIP",
    kubernetes_image_pull_secrets  = []
    kubernetes_disabled_components = ["deployment", "secret"],
    kubernetes_ingress_annotations = {}, kubernetes_ingress_secret_name = "authentik-outpost-tls"
  })
}

resource "authentik_provider_proxy" "providers" {
  for_each = local.proxy_apps

  name                          = format("%s proxy", each.key)
  external_host                 = format("https://%s.%s%s", each.key, var.cluster_domain, lookup(each.value, "external_host_path", ""))
  internal_host                 = lookup(each.value, "internal_host", "")
  authorization_flow            = data.authentik_flow.default-authorization.id
  mode                          = lookup(each.value, "mode", "forward_single")
  basic_auth_enabled            = lookup(each.value, "basic_auth_enabled", false)
  basic_auth_password_attribute = format("%s_password", each.key)
  basic_auth_username_attribute = format("%s_user", each.key)
  token_validity                = "days=14"
}

resource "authentik_provider_oauth2" "providers" {
  for_each = local.oauth2_apps

  name               = each.key
  client_id          = lookup(var.oauth2_settings, format("%s_client_id", each.key))
  client_secret      = lookup(var.oauth2_settings, format("%s_client_secret", each.key))
  authorization_flow = data.authentik_flow.default-authorization.id
  signing_key        = data.authentik_certificate_key_pair.generated.id
  property_mappings  = concat(data.authentik_scope_mapping.scopes.ids, lookup(each.value, "extra_scopes", []))
  redirect_uris      = [lookup(var.oauth2_settings, format("%s_redirect_url", each.key))]
  sub_mode           = lookup(each.value, "sub_mode", "hashed_user_id")
}

resource "authentik_application" "name" {
  for_each = merge(local.proxy_apps, local.oauth2_apps, local.ldap_apps)

  name              = each.key
  slug              = each.key
  protocol_provider = lookup(authentik_provider_proxy.providers, each.key, lookup(authentik_provider_oauth2.providers, each.key, {})).id
  group             = lookup(each.value, "group", "System")
}
