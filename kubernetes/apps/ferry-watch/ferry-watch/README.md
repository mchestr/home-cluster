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

Do all of this before the change reaches `main`. Authelia stops starting once its config names a client whose
1Password fields don't exist.

1. **1Password item `authelia`**: generate `FERRY_WATCH_OAUTH_CLIENT_ID`, `FERRY_WATCH_OAUTH_CLIENT_SECRET` and
   `FERRY_WATCH_OAUTH_CLIENT_SECRET_HASH` with the script in `default/authelia/app/README.md` (`APP=FERRY_WATCH`).
2. **1Password item `cloudnative-pg`**: add these fields (hex, so nothing needs escaping in a URI):
   - `ferrywatch_postgres_username` = `ferrywatch` (components/cnpg builds its URI from the app name).
   - `ferrywatch_postgres_password`.
   - `ferrywatch_web_password`.
   - `ferrywatch_control_password`.

   For example, `op item edit cloudnative-pg "ferrywatch_web_password[password]=$(openssl rand -hex 24)"`.
3. **1Password item `ferry-watch`**: add the checkout ticket key and the Web Push key. Generate them with:

   ```sh
   docker run --rm ghcr.io/mchestr/ferry-watch-control:<version> ferry-web keys
   ```

   That prints `FERRY_WATCH_CHECKOUT_KEY`, `FERRY_WATCH_VAPID_KEY` and the checkout key's public half. Store the
   two keys in the item. Put the public half in `ferry.control.pod.vncPubkeys` in `app/helmrelease.yaml`; it
   isn't a secret.
4. **Values in `app/helmrelease.yaml`**:
   - The three images at the same Ferry Watch release.
   - `ferry.browserImage.tag` with its digest (`<version>@sha256:…`).
   - `ferry.control.pod.vncPubkeys`.
   - `ferry.web.identity.bootstrapAdmins[0].username`: your lldap username.
   - `ferry.web.kofiUrl`, if you want the donation link.

   The render fails until the digest and the public key are filled in, so flux-local catches a premature merge.
5. **lldap**: create the group `ferry-watch` and add people to it. Admins in `admin` get in too.
6. **Cloudflare**: `task terraform:cf:plan` and then `task terraform:cf:apply`.

## Cutover from the single-tenant app

1. Run the new stack on `ferry-next.chestr.dev` until you have signed in there.
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

ferry-web signs checkout tickets with `FERRY_WATCH_CHECKOUT_KEY`. Each browser pod checks them against the public
keys in `ferry.control.pod.vncPubkeys`, as they were when the pod started.

1. Generate a new pair with `ferry-web keys`. Add its public half as a second key (`k1:<old>,k2:<new>`), keep
   signing with `k1`, and deploy.
2. Wait 26 hours, a browser pod's longest life, so that every running pod knows `k2`. Then store the new private
   key as `FERRY_WATCH_CHECKOUT_KEY` and set `ferry.web.checkout.keyId: k2`.
3. Drop `k1` from `vncPubkeys`.
