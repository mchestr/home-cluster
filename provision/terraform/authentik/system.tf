data "authentik_certificate_key_pair" "generated" {
  name = "authentik Self-signed Certificate"
}

resource "authentik_tenant" "home" {
  domain           = data.sops_file.authentik_secrets.data["cluster_domain"]
  default          = false
  branding_title   = "Home"
  branding_logo    = "/static/dist/assets/icons/icon_left_brand.svg"
  branding_favicon = "/static/dist/assets/icons/icon.png"

  flow_authentication = authentik_flow.authentication.uuid
  flow_invalidation   = data.authentik_flow.default-invalidation.id
  flow_recovery       = data.authentik_flow.default-recovery.id
  flow_user_settings  = data.authentik_flow.default-user-settings.id
  event_retention     = "days=365"
}
