resource "authentik_stage_identification" "authentication-identification" {
  name               = "authentication-identification"
  user_fields        = ["username"]
  sources            = [authentik_source_oauth.google.uuid, authentik_source_plex.name.uuid]
  show_source_labels = true
  show_matched_user  = true
}

resource "authentik_stage_password" "authentication-password" {
  name                          = "authentication-password"
  backends                      = ["authentik.core.auth.InbuiltBackend"]
  configure_flow                = data.authentik_flow.default-password-change.id
  failed_attempts_before_cancel = 3
}

resource "authentik_stage_authenticator_validate" "authentication-mfa-validation" {
  name                  = "authentication-mfa-validation"
  device_classes        = ["static", "totp"]
  not_configured_action = "skip"
}

resource "authentik_stage_user_login" "authentication-login" {
  name = "authentication-login"
}
