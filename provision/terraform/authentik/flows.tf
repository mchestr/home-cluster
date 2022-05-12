data "authentik_flow" "default-authorization" {
  slug = "default-provider-authorization-implicit-consent"
}

data "authentik_flow" "default-authentication" {
  slug = "default-source-authentication"
}

data "authentik_flow" "default-enrollment" {
  slug = "default-source-enrollment"
}

data "authentik_flow" "default-password-change" {
  slug = "default-password-change"
}

data "authentik_flow" "default-invalidation" {
  slug = "default-invalidation-flow"
}

data "authentik_flow" "default-user-settings" {
  slug = "default-user-settings-flow"
}

resource "authentik_flow" "authentication" {
  name               = "authentication-flow"
  title              = "Welcome!"
  slug               = "authentication-flow"
  designation        = "authentication"
  background         = "/static/dist/assets/images/flow_background.jpg"
  policy_engine_mode = "all"
}

resource "authentik_flow_stage_binding" "authentication-flow-binding-00" {
  target               = authentik_flow.authentication.uuid
  stage                = authentik_stage_captcha.recaptcha.id
  re_evaluate_policies = true
  order  = 0
}

resource "authentik_flow_stage_binding" "authentication-flow-binding-10" {
  target = authentik_flow.authentication.uuid
  stage  = authentik_stage_identification.authentication-identification.id
  order  = 10
}

resource "authentik_flow_stage_binding" "authentication-flow-binding-20" {
  target = authentik_flow.authentication.uuid
  stage  = authentik_stage_password.authentication-password.id
  order  = 20
}

resource "authentik_flow_stage_binding" "authentication-flow-binding-30" {
  target = authentik_flow.authentication.uuid
  stage  = authentik_stage_authenticator_validate.authentication-mfa-validation.id
  order  = 30
}

resource "authentik_flow_stage_binding" "authentication-flow-binding-100" {
  target = authentik_flow.authentication.uuid
  stage  = authentik_stage_user_login.authentication-login.id
  order  = 100
}
