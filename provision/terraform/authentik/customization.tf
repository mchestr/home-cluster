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
  for_each = toset(
    concat(
      tolist(local.admin_apps),
      tolist(concat(
        tolist(local.media_apps),
        tolist(["paperless"])
      ))
    )
  )

  target = authentik_application.name[each.key].uuid
  group  = authentik_group.system-admins.id
  order  = 5
}

resource "authentik_policy_binding" "media-users-apps" {
  for_each = local.media_apps

  target = authentik_application.name[each.key].uuid
  group  = authentik_group.media-users.id
  order  = 10
}

resource "authentik_policy_binding" "paperless-users-app" {
  target = authentik_application.name["paperless"].uuid
  group  = authentik_group.paperless-users.id
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
