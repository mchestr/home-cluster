resource "authentik_stage_identification" "authentication-identification" {
  name           = "authentication-identification"
  user_fields    = ["username", "email"]
  sources        = [authentik_source_oauth.google.id, authentik_source_plex.name.id]
  password_stage = authentik_stage_password.name.id
}
