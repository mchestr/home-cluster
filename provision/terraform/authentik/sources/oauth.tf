resource "authentik_source_oauth" "google" {
  name                = "Login with Google"
  slug                = "google"
  authentication_flow = data.authentik_flow.default-authentication-flow.id
  enrollment_flow     = data.authentik_flow.default-enrollment-flow.id

  provider_type   = "google"
  consumer_key    = data.sops_file.authentik_secrets.data["google_consumer_key"]
  consumer_secret = data.sops_file.authentik_secrets.data["google_consumer_secret"]
}
