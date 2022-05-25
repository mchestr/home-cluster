data "authentik_scope_mapping" "scopes" {
  managed_list = [
    "goauthentik.io/providers/oauth2/scope-email",
    "goauthentik.io/providers/oauth2/scope-openid",
    "goauthentik.io/providers/oauth2/scope-profile"
  ]
}

resource "authentik_policy_reputation" "name" {
  name           = "reputation"
  check_ip       = true
  check_username = true
}

resource "authentik_policy_binding" "reputation-low" {
  target = authentik_flow_stage_binding.authentication-flow-binding-00.id
  policy = authentik_policy_reputation.name.id
  order  = 0
}

resource "authentik_policy_binding" "system-admins-apps" {
  for_each = authentik_application.name

  target = each.value.uuid
  group  = authentik_group.system-admins.id
  order  = 5
}

resource "authentik_policy_binding" "media-users-apps" {
  for_each = local.media_apps

  target = each.value.uuid
  group  = authentik_group.media-users.id
  order  = 10
}

resource "authentik_policy_binding" "home-users-app" {
  for_each = local.home_apps

  target = each.value.uuid
  group  = authentik_group.home-users.id
  order  = 10
}

resource "authentik_scope_mapping" "x-plex-token" {
  name       = "x-plex-token"
  scope_name = "x-plex-token"
  expression = <<EOF
from authentik.sources.plex.models import PlexSourceConnection
connection = PlexSourceConnection.objects.filter(user=request.user).first()
if not connection:
    return {}
return {
    "ak_proxy": {
        "user_attributes": {
            "additionalHeaders": {
                "X-Plex-Token": connection.plex_token
            }
        }
    }
}
EOF
}

resource "authentik_scope_mapping" "oidc-scope-minio" {
  name       = "OIDC-Scope-minio"
  scope_name = "minio"
  expression = <<EOF
return {
    "policy": "readwrite",
}
EOF
}
