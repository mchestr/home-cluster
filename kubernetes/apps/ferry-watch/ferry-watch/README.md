# Ferry Watch (multi-tenant)

[github.com/mchestr/ferry-watch](https://github.com/mchestr/ferry-watch), deployed with app-template
(`app/helmrelease.yaml`). It runs beside the single-tenant app in `kubernetes/apps/default/ferry-watch` until the
cutover below.

| Piece | Where |
|---|---|
| `ferry-web`: sign-in (Authelia OIDC), the API and the dashboard | `ferry-next.chestr.dev` on envoy-external |
| `ferry-control`: the hub and the fleet of browser pods | in-cluster only |
| `vnc-edge`: the checkout page, while a cart is held | `ferry-checkout.chestr.dev` on envoy-external |
| `ferry-db`: creates the database and runs migrations | a Helm hook Job, before every install and upgrade |
| One browser pod per watched trip | namespace `ferry-watch-browsers`, created by the HelmRelease |

The HelmRelease also carries the browser namespace's guard rails (quotas, network policies, RBAC) and three
ValidatingAdmissionPolicies. Those policies admit only the exact pod ferry-control builds, and nobody can change
or `exec` into one afterwards. The ferry-watch repo's CI renders `app/helmrelease.yaml` and tests those
policies against a real API server, so change the copy there too (`deploy/helmrelease.yaml`).

Outside this directory:
- The OIDC client and its `ferry-watch` authorization policy in Authelia: `default/authelia/app/resources/configuration.yaml`.
- The database login roles `ferrywatch_web` and `ferrywatch_control`: `database/cloudnative-pg/cluster/cluster17.yaml`, with passwords from `database/cloudnative-pg/roles/`.
- An smtp-relay ingress rule for ferry-web.
- Cilium's `dnsProxy.dnsRejectResponseCode`.
- A Silence for the browser namespace.
- Fluent Bit and descheduler exclusions for the browser namespace.
- A Cloudflare rule turning off Rocket Loader and email obfuscation on the ferry hosts: `terraform/cloudflare/rulesets.tf`.

## Before the first deploy

Do all of this before the change reaches `main`.

### 1Password

Signed in to `op` (vault `kubernetes`), with Docker, `jq` and `uv`, from a checkout of
[ferry-watch](https://github.com/mchestr/ferry-watch) (for `ferry-web keys`; once a release image exists,
`docker run --rm ghcr.io/mchestr/ferry-watch-control:<version> ferry-web keys` does the same). The generated values
never reach the screen or your shell history; they are passed to `op` as arguments.

```sh
VAULT=kubernetes
pw() { op item create --category password --generate-password=letters,digits,32 --dry-run --format json | jq -r '.fields[0].value'; }

# 1. The OIDC client, in item authelia (generated with the cluster's Authelia version).
AUTHELIA=authelia/authelia:4.39.28
CLIENT_ID="$(docker run --rm "$AUTHELIA" authelia crypto rand --length 72 --charset rfc3986 | awk '/^Random Value:/ {print $3}')"
SECRET_OUT="$(docker run --rm "$AUTHELIA" authelia crypto hash generate argon2 --random --random.length 64 --random.charset alphanumeric)"
CLIENT_SECRET="$(printf '%s\n' "$SECRET_OUT" | awk '/^Random Password:/ {print $3}')"
CLIENT_SECRET_HASH="$(printf '%s\n' "$SECRET_OUT" | awk '/^Digest:/ {print $2}')"
case "$CLIENT_SECRET_HASH" in '$argon2id$'*) echo "client id ${#CLIENT_ID} chars, secret ${#CLIENT_SECRET} chars, hash ok" ;; *) echo "no hash: stop" ;; esac
op item edit authelia --vault "$VAULT" \
  "FERRY_WATCH_OAUTH_CLIENT_ID[password]=$CLIENT_ID" \
  "FERRY_WATCH_OAUTH_CLIENT_SECRET[password]=$CLIENT_SECRET" \
  "FERRY_WATCH_OAUTH_CLIENT_SECRET_HASH[password]=$CLIENT_SECRET_HASH" >/dev/null
unset CLIENT_ID SECRET_OUT CLIENT_SECRET CLIENT_SECRET_HASH

# 2. The database owner (components/cnpg builds its URI from the app name, so it must be "ferrywatch") and
#    the two login roles, in item cloudnative-pg.
op item edit cloudnative-pg --vault "$VAULT" \
  "ferrywatch_postgres_username[text]=ferrywatch" \
  "ferrywatch_postgres_password[password]=$(pw)" \
  "ferrywatch_web_password[password]=$(pw)" \
  "ferrywatch_control_password[password]=$(pw)" >/dev/null

# 3. The checkout ticket key (stored as k1:<key>) and the Web Push key, in item ferry-watch.
KEYS="$(uv run --isolated --no-dev --extra control ferry-web keys)"
op item edit ferry-watch --vault "$VAULT" \
  "FERRY_WATCH_CHECKOUT_KEY[password]=$(printf '%s\n' "$KEYS" | sed -n 's/^FERRY_WATCH_CHECKOUT_KEY=//p')" \
  "FERRY_WATCH_VAPID_KEY[password]=$(printf '%s\n' "$KEYS" | sed -n 's/^FERRY_WATCH_VAPID_KEY=//p')" >/dev/null
printf '%s\n' "$KEYS" | grep '^k1:'   # the public half: ferry.control.pod.vncPubkeys
unset KEYS
```

To check the fields exist (labels only, no values):

```sh
for i in authelia cloudnative-pg ferry-watch; do
  op item get "$i" --vault "$VAULT" --format json | jq -r --arg i "$i" '.fields[].label | select(test("FERRY_WATCH|ferrywatch")) | "\($i): \(.)"'
done
```

Authelia only enables the client once its fields reach `authelia-secret`, so a missing field disables sign-in
to Ferry Watch rather than stopping Authelia.

### Values in `app/helmrelease.yaml`

- The three images at the same Ferry Watch release, each as `<version>@sha256:<digest>`
  (`docker buildx imagetools inspect ghcr.io/mchestr/ferry-watch-browser:<version>` shows the digest).
- `ferry.control.pod.vncPubkeys`: the `k1:…` line from step 3. It isn't a secret.
- `ferry.web.identity.bootstrapAdmins[0].username`: your lldap username.
- `ferry.web.kofiUrl`, if you want the donation link.

The render fails until the digests and the public key are filled in, so flux-local catches a premature merge.
Merging while it is red would also hold back every Renovate automerge, which waits on flux-local.

Then copy the file to the ferry-watch repo's `deploy/helmrelease.yaml`, which CI tests.

### Elsewhere

- **Cloudflare**: `task terraform:cf:plan`, then `task terraform:cf:apply`.
- **lldap**: create the group `ferry-watch`. Members and `admin` can sign in to Ferry Watch.

### Before inviting anyone

An invitee's lldap account is also an account for every other Authelia OIDC client: those want `two_factor`,
and anyone with a password can enrol a second factor. Before adding anyone but yourself to lldap, give
Autobrr, Grafana, Immich, Paperless and Windmill their own `authorization_policies` limited to the groups that
use them (`default/authelia/app/resources/configuration.yaml`, like `ferry-watch`'s).

## Cutover from the single-tenant app

1. Run the new stack on `ferry-next.chestr.dev` until you have signed in there. Until the cutover, the checkout
   page's "Back to Ferry Watch" links and its retry after an expired ticket lead to `ferry.chestr.dev` (built
   into the vnc-edge image), which is still the old app, so test a checkout end to end after the cutover.
2. Cutover:
   - Scale `kubernetes/apps/default/ferry-watch` to `replicas: 0`, turn its route off, and set its PVC to
     `kustomize.toolkit.fluxcd.io/prune: disabled`.
   - Set `ferry.hosts.dashboard: ferry.chestr.dev`. That moves the route, `baseUrl` and the OIDC redirect
     URI together.

   Pin the old app's image by digest first, so that a revert brings back exactly what ran.
3. Wait until all of these hold:
   - 14 days have passed.
   - A real guest checkout has worked on the new stack.
   - No forced login wall has been seen since the cutover.

   Then delete `kubernetes/apps/default/ferry-watch` (and its entry in `default/kustomization.yaml`) and the
   old fields of the `ferry-watch` item (`BCF_USER`, `BCF_PASS`), and remove the `ferry-next` redirect URI
   from the Authelia client.

## Rotating the checkout key

ferry-web signs checkout tickets with `FERRY_WATCH_CHECKOUT_KEY`, stored as `<id>:<key>`. Each browser pod checks
them against the public keys in `ferry.control.pod.vncPubkeys`, as they were when the pod started.

1. Generate a new pair with `ferry-web keys --key-id k2`. Add its public half as a second key
   (`k1:<old>,k2:<new>`) and deploy; ferry-web keeps signing with `k1`.
2. Wait 26 hours, a browser pod's longest life, so that every running pod knows `k2`. Then put the new
   `k2:<key>` in `FERRY_WATCH_CHECKOUT_KEY`. The key and its id change together; Reloader restarts ferry-web.
3. Drop `k1` from `vncPubkeys`.
