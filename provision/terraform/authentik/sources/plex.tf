resource "authentik_source_plex" "name" {
  name                = "Login with Plex"
  slug                = "plex"
  authentication_flow = data.authentik_flow.default-authentication-flow.id
  enrollment_flow     = data.authentik_flow.default-enrollment-flow.id
  client_id           = data.sops_file.authentik_secrets.data["plex_client_id"]
  plex_token          = data.sops_file.authentik_secrets.data["plex_token"]
  allowed_servers = [
    data.sops_file.authentik_secrets.data["plex_server"]
  ]
}
