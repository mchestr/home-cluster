resource "authentik_flow" "authentication-flow" {
  name               = "authentication-flow"
  title              = "Authentication Flow"
  slug               = "authentication-flow"
  designation        = "authentication"
  background         = "/static/dist/assets/images/flow_background.jpg"
  policy_engine_mode = "all"
}

resource "authentik_stage_identification" "name" {
  name               = "authentication-identification"
  user_fields        = ["username", "email"]
  sources            = [authentik_source_oauth.google.uuid, authentik_source_plex.name.id]
  password_stage     = authentik_stage_password.name.id
  show_source_labels = true
  show_matched_user  = true
}

resource "authentik_stage_password" "name" {
  name     = "default-authentication-password"
  backends = ["authentik.core.auth.InbuiltBackend"]
}
