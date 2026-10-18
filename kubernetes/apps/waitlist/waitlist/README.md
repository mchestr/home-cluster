# Waitlist

[github.com/mchestr/waitlist](https://github.com/mchestr/waitlist) (formerly Ferry Watch), deployed with
app-template (`app/helmrelease.yaml`): one dashboard that watches several reservation systems. BC Ferries works as
it did in Ferry Watch; Buntzen Lake day passes are the second provider (alerts only).

| Piece | Where |
|---|---|
| `waitlist-web`: sign-in (Authelia OIDC), the API and the dashboard | `waitlist.chestr.dev` on envoy-external |
| `waitlist-control`: the hub, the fleet of browser pods, and the Buntzen check loop | in-cluster only |
| `waitlist-fetcher`: the only process that calls Buntzen's booking site (`api.yodelpass.com`) | in-cluster only |
| `vnc-edge`: the checkout page, while a BC Ferries cart is held | `waitlist-checkout.chestr.dev` on envoy-external |
| `waitlist-db`: creates the database and runs migrations | a Helm hook Job, before every install and upgrade |
| One browser pod per watched BC Ferries trip | namespace `waitlist-browsers`, created by the HelmRelease |

The HelmRelease also carries the browser namespace's guard rails (quotas, network policies, RBAC) and three
ValidatingAdmissionPolicies (`wl-browser-pod`, `wl-browser-pod-lock`, `wl-ns-objects`). Those policies admit only
the exact pod waitlist-control builds, and nobody can change or `exec` into one afterwards. The waitlist repo's CI
renders `app/helmrelease.yaml` and tests those policies against a real API server, so change the copy there too
(`deploy/helmrelease.yaml`). The two copies differ only in the `streamViewer:` and `offer:` lines: the app repo
keeps both `"off"`, and this one chooses (`tests/test_deploy.py`, `test_home_cluster_runs_this_copy`).

Outside this directory:
- The OIDC client and its `waitlist` authorization policy in Authelia: `default/authelia/app/resources/configuration.yaml`.
- The database login roles `waitlist_web` and `waitlist_control`: `database/cloudnative-pg/cluster/cluster17.yaml`, with passwords from `database/cloudnative-pg/roles/`. Until a follow-up removes them (Phase 2 step 8), the same file also holds two `ensure: absent` entries for Ferry Watch's old login roles.
- An smtp-relay ingress rule for waitlist-web.
- Cilium's `dnsProxy.dnsRejectResponseCode`.
- A Silence for the browser namespace.
- Fluent Bit and descheduler exclusions for the browser namespace.
- A Cloudflare rule turning off Rocket Loader and email obfuscation on the Waitlist hosts: `terraform/cloudflare/rulesets.tf`.
- The lldap group `waitlist` (UI, not git).

## 1Password

Vault `kubernetes`. Values never reach the screen or your shell history: they are passed to `op` as arguments.

| Item | Field | Source |
|---|---|---|
| `waitlist` (its own item) | `WAITLIST_CHECKOUT_KEY` | `waitlist-web keys` (stored as `k1:<key>`). Its public half goes into `waitlist.control.pod.vncPubkeys`. |
| `waitlist` | `WAITLIST_VAPID_KEY` | `waitlist-web keys`, the same run. Push subscriptions are bound to it. |
| `authelia` | `WAITLIST_OAUTH_CLIENT_ID`, `WAITLIST_OAUTH_CLIENT_SECRET`, `WAITLIST_OAUTH_CLIENT_SECRET_HASH` | `authelia crypto rand` / `authelia crypto hash generate` |
| `cloudnative-pg` | `waitlist_postgres_username` (= `waitlist`), `waitlist_postgres_password`, `waitlist_web_password`, `waitlist_control_password` | generated |

waitlist-fetcher has no field: it holds no secret. `app/externalsecret.yaml` gives waitlist-web the first five keys
of the `waitlist` Secret and waitlist-control the last; `components/cnpg` makes `waitlist-initdb-secret` and
`waitlist-pguser-secret` for the db hook.

The commands are in the runbook, Phase 0 step 4. Authelia only enables the client once its fields reach
`authelia-secret`, so a missing field disables sign-in to Waitlist rather than stopping Authelia.

## Values in `app/helmrelease.yaml`

- The three images at the same Waitlist release, each as `<version>@sha256:<digest>`: `waitlist.browserImage.tag`,
  waitlist-web's `&image` (waitlist-control, waitlist-fetcher and the db hook use the same anchor) and vnc-edge's.
  `docker buildx imagetools inspect ghcr.io/mchestr/waitlist-browser:<version>` shows the digest.
- `waitlist.control.pod.vncPubkeys`: the `k1:…` public half of `WAITLIST_CHECKOUT_KEY`. It isn't a secret.
- `waitlist.web.identity.bootstrapAdmins[0].username`: your lldap username.
- `waitlist.checkout.streamViewer`: who gets the streamed checkout viewer (`"off"`, `"admins"`, `"everyone"`).
- `waitlist.providers.buntzen.offer`: who may create Buntzen watches (`"off"`, `"admins"`, `"everyone"`).
  `requestsPerMinute` is waitlist-control's budget, `fetcherPerMinute` waitlist-fetcher's own hard cap
  (`1 ≤ requestsPerMinute ≤ fetcherPerMinute ≤ 30`).
- `waitlist.web.kofiUrl`, if you want the donation link.

The render fails until the digests and the public key are filled in (and for a bare `off`, or a bad rate), so
flux-local catches a premature merge. Merging while it is red would also hold back every Renovate automerge, which
waits on flux-local. Keep `streamViewer:` and `offer:` free of trailing comments: the app repo's test masks those
lines whole.

## waitlist-fetcher

Buntzen's availability comes from Yodel's unofficial API. waitlist-control schedules every check (07:00:02 on
release mornings, then every 30-60 s, every 30 min out of season), coalesces identical queries across users, and
writes the results; it has no internet egress of its own. waitlist-fetcher makes the HTTPS request and parses the
answer into a closed, typed result (`src/waitlist/fetchwire.py`). It has:

- no database login, no Secret, no ServiceAccount token and no RBAC (its ServiceAccount is bound to nothing);
- ingress only from waitlist-control's pods on 8767 (`NetworkPolicy waitlist-fetcher`);
- egress only to kube-dns for `api.yodelpass.com`, and that name on 443, never to a private, CGNAT, link-local or
  loopback address (`CiliumNetworkPolicy waitlist-fetcher-cilium`, with an `egressDeny` block), and the process
  itself refuses non-public DNS answers;
- one replica, its own rate cap (`fetcherPerMinute`) and its logs collected (no bodies, no headers).

If it is down, Buntzen cards say "Checks not running", no watch is charged, waitlist-control retries every 30 s
and admins get one `checker_down` alert after 3 minutes. `kubectl -n waitlist logs deploy/waitlist-fetcher` shows
one line per fetch (`result=ok`, or the error kind).

- **Pause Buntzen** without a deploy: Admin → Providers → pause. Or stop offering it: `offer: "off"` here (one
  line, no release), which renders no Buntzen keys into any config.
- **Open it to everyone** once a real capture has confirmed the parser: `offer: "everyone"`.
- **If checks fail with `network` or `timeout`** while Yodel is up (the fetcher logs `result=failed error=network`
  or `error=timeout`; Admin → Providers shows Fetcher `OK` and Last error `network` or `timeout`; cards say
  "Problem" after 3 failures), the fetcher's own egress is the suspect: DNS, or the `toFQDNs` rule. If the
  `egressDeny` block is what breaks DNS on this Cilium, drop that block (the resolver check remains). The fetcher
  still answers waitlist-control then, so this is never `fetcher_unavailable`.
- **`fetcher_unavailable`** (cards say "Checks not running", Admin → Providers shows Fetcher `Down`) means
  waitlist-control can't reach the fetcher: its Service, waitlist-control's egress policy, or the fetcher pod.
- **A new provider** later: add its hosts to `waitlist-fetcher-cilium`'s DNS and `toFQDNs` rules, and a
  `waitlist.providers.<id>` entry; both copies of the HelmRelease.

## Rotating the checkout key

waitlist-web signs checkout tickets with `WAITLIST_CHECKOUT_KEY`, stored as `<id>:<key>`. Each browser pod checks
them against the public keys in `waitlist.control.pod.vncPubkeys`, as they were when the pod started. As in
Phase 0 step 4, the private key goes straight from `waitlist-web keys` into 1Password and is never printed. Use
the running release's image for `RELEASE`.

1. Generate a new pair. Its private half waits in a field of its own; only the public half is printed:
   ```sh
   RELEASE=ghcr.io/mchestr/waitlist-control:1.0.0
   KEYS="$(docker run --rm "$RELEASE" waitlist-web keys --key-id k2)"
   op item edit waitlist --vault kubernetes \
     "WAITLIST_CHECKOUT_KEY_NEXT[password]=$(printf '%s\n' "$KEYS" | sed -n 's/^WAITLIST_CHECKOUT_KEY=//p')" >/dev/null
   printf '%s\n' "$KEYS" | tail -n 1   # k2:<base64url>, the public half (not a secret)
   unset KEYS
   ```
   Add that public half as a second key (`k1:<old>,k2:<new>`) and deploy (both copies); waitlist-web keeps
   signing with `k1`. `WAITLIST_CHECKOUT_KEY_NEXT` stays in 1Password: the ExternalSecret's template doesn't
   read it.
2. Wait 26 hours, a browser pod's longest life, so that every running pod knows `k2`. Then move the new key into
   place; the key and its id change together:
   ```sh
   NEXT="$(op read op://kubernetes/waitlist/WAITLIST_CHECKOUT_KEY_NEXT)"
   case "$NEXT" in
     k2:?*) op item edit waitlist --vault kubernetes "WAITLIST_CHECKOUT_KEY[password]=$NEXT" >/dev/null \
              && op item edit waitlist --vault kubernetes 'WAITLIST_CHECKOUT_KEY_NEXT[delete]' >/dev/null \
              && echo "k2 in place" ;;
     *) echo "no k2 key: stop" ;;
   esac
   unset NEXT
   ```
   Reloader restarts waitlist-web once the ExternalSecret refreshes (`task kubernetes:sync-secrets` to not wait
   the hour). Phase S step 4's check then prints `pubkey ok` against any running browser pod.
3. Drop `k1` from `vncPubkeys`.

Rotating the VAPID key is not covered here: every push subscription is bound to it, so every device would have to
turn alerts on again.

## Before inviting anyone

An invitee's lldap account is also an account for every other Authelia OIDC client: those want `two_factor`,
and anyone with a password can enrol a second factor. Before adding anyone but yourself to lldap, give
Autobrr, Grafana, Immich, Paperless and Windmill their own `authorization_policies` limited to the groups that
use them (`default/authelia/app/resources/configuration.yaml`, like `waitlist`'s).

## Runbook: replace Ferry Watch with Waitlist

Nobody uses Ferry Watch, so there is no data to carry over: Waitlist starts with an empty database, and Ferry
Watch is deleted by the same change that adds Waitlist. Users sign in at `waitlist.chestr.dev` and turn alerts on
again. Run the phases in order:

| Phase | What happens | Can be undone by |
|---|---|---|
| 0 | GitHub, the 1.0.0 release, 1Password, lldap, the digests | nothing to undo in the cluster |
| 1 | Merge: Flux deploys Waitlist and uninstalls Ferry Watch; Cloudflare | reverting every commit the change put on main (Ferry Watch comes back as it was) |
| S | Smoke test | nothing changes |
| 2 | Delete what Flux leaves of Ferry Watch, its database and its 1Password fields | nothing: Ferry Watch could only come back empty |

`pg` runs `psql` as the superuser on the current primary of `postgres17` (the `cnpg` krew plugin, from
`task workstation:krew`):

```sh
pg() { kubectl cnpg psql -n database postgres17 -- "$@"; }
```

### Phase 0: before the merge

1. **Rename the repo:** `gh repo rename waitlist -R mchestr/ferry-watch` (or GitHub → Settings → Repository
   name). GitHub redirects the old URLs; the old `ghcr.io/mchestr/ferry-watch-*` packages keep their names.

2. **Release 1.0.0.** Merge the waitlist app PR to `main` (it sets `version = "1.0.0"`). Run the Release workflow
   (`gh workflow run release.yml -R mchestr/waitlist --ref main`); it tags `v1.0.0` and starts CI on the tag,
   which pushes `ghcr.io/mchestr/waitlist-{control,browser,vnc-edge}:1.0.0` once its tests pass, several minutes
   later. Wait for that run (or watch Actions → CI, branch `v1.0.0`); the first command waits until the Release
   workflow has started it:
   ```sh
   until id=$(gh run list -R mchestr/waitlist --workflow ci.yml --branch v1.0.0 --limit 1 --json databaseId -q '.[0].databaseId') && [ -n "$id" ]; do sleep 10; done
   gh run watch -R mchestr/waitlist --exit-status "$id"
   ```

3. **Make the three packages public.** New GHCR packages start private, and the cluster pulls with no
   `imagePullSecrets`. GitHub → Packages → each `waitlist-*` → Package settings → Change visibility → Public. Then
   check an anonymous pull, and record each digest (public now, so no `docker login` is needed):
   ```sh
   for p in control browser vnc-edge; do
     t=$(curl -fsS "https://ghcr.io/token?scope=repository:mchestr/waitlist-$p:pull" | jq -r .token)
     curl -fsSI -H "Authorization: Bearer $t" -H 'Accept: application/vnd.oci.image.index.v1+json' \
       "https://ghcr.io/v2/mchestr/waitlist-$p/manifests/1.0.0" | head -1    # HTTP/2 200, three times
   done
   for p in control browser vnc-edge; do
     printf '%s 1.0.0@%s\n' "$p" "$(docker buildx imagetools inspect "ghcr.io/mchestr/waitlist-$p:1.0.0" | awk '/^Digest:/ {print $2}')"
   done   # three lines, each ending in sha256:<64 hex>
   ```

4. **1Password.** Signed in to `op`, with Docker and `jq`:
   ```sh
   VAULT=kubernetes
   pw() { op item create --category password --generate-password=letters,digits,32 --dry-run --format json | jq -r '.fields[0].value'; }

   # a. The item, with a fresh checkout key and VAPID key from the release. Nothing is written unless both came out,
   #    and nothing at all once the item exists: a second item titled waitlist would stop its Secret syncing.
   if op item get waitlist --vault "$VAULT" >/dev/null 2>&1; then
     echo "item waitlist exists: keep its keys (Phase S step 4's want= line prints the public half), or delete it first"
   else
     KEYS="$(docker run --rm ghcr.io/mchestr/waitlist-control:1.0.0 waitlist-web keys)"
     case "$KEYS" in
       *'WAITLIST_CHECKOUT_KEY=k1:'?*'WAITLIST_VAPID_KEY='?*)
         op item create --vault "$VAULT" --category password --title waitlist >/dev/null \
           && op item edit waitlist --vault "$VAULT" \
             "WAITLIST_CHECKOUT_KEY[password]=$(printf '%s\n' "$KEYS" | sed -n 's/^WAITLIST_CHECKOUT_KEY=//p')" \
             "WAITLIST_VAPID_KEY[password]=$(printf '%s\n' "$KEYS" | sed -n 's/^WAITLIST_VAPID_KEY=//p')" >/dev/null \
           && printf '%s\n' "$KEYS" | tail -n 1 ;;  # k1:<base64url>, the checkout key's public half (not a secret): keep it for step 6
       *) echo "no keys: stop" ;;
     esac
     unset KEYS
   fi

   # b. A new OIDC client, in item authelia, generated with the image the cluster runs (default/authelia).
   AUTHELIA=ghcr.io/authelia/authelia:4.39.28
   CLIENT_ID="$(docker run --rm "$AUTHELIA" authelia crypto rand --length 72 --charset rfc3986 | awk '/^Random Value:/ {print $3}')"
   SECRET_OUT="$(docker run --rm "$AUTHELIA" authelia crypto hash generate argon2 --random --random.length 64 --random.charset alphanumeric)"
   CLIENT_SECRET="$(printf '%s\n' "$SECRET_OUT" | awk '/^Random Password:/ {print $3}')"
   CLIENT_SECRET_HASH="$(printf '%s\n' "$SECRET_OUT" | awk '/^Digest:/ {print $2}')"
   case "${#CLIENT_ID}:${#CLIENT_SECRET}:$CLIENT_SECRET_HASH" in  # written only with all three, at their lengths
     72:64:'$argon2id$'*)
       op item edit authelia --vault "$VAULT" \
         "WAITLIST_OAUTH_CLIENT_ID[password]=$CLIENT_ID" \
         "WAITLIST_OAUTH_CLIENT_SECRET[password]=$CLIENT_SECRET" \
         "WAITLIST_OAUTH_CLIENT_SECRET_HASH[password]=$CLIENT_SECRET_HASH" >/dev/null && echo "OIDC client stored" ;;
     *) echo "no client id, secret or hash: stop" ;;
   esac
   unset CLIENT_ID SECRET_OUT CLIENT_SECRET CLIENT_SECRET_HASH

   # c. The database owner (components/cnpg names it after APP, so it must be "waitlist") and the two login
   #    roles, in item cloudnative-pg.
   op item edit cloudnative-pg --vault "$VAULT" \
     "waitlist_postgres_username[text]=waitlist" \
     "waitlist_postgres_password[password]=$(pw)" \
     "waitlist_web_password[password]=$(pw)" \
     "waitlist_control_password[password]=$(pw)" >/dev/null
   ```
   Check the fields by label only:
   ```sh
   for i in authelia cloudnative-pg waitlist; do op item get "$i" --vault "$VAULT" --format json \
     | jq -r --arg i "$i" '.fields[].label | select(test("WAITLIST|waitlist")) | "\($i): \(.)"'; done
   ```
   It lists the three `authelia` fields, the four `cloudnative-pg` fields and the two `waitlist` fields.

5. **lldap.** Create the group `waitlist` and add yourself to it. Its members and `admin` can sign in to Waitlist.

6. **Fill in `app/helmrelease.yaml`** on this branch, replacing the three `tag: 1.0.0  # …` placeholder lines and
   the `vncPubkeys: ""  # …` line, comments and all:
   - `waitlist.browserImage.tag`: `1.0.0@sha256:<browser digest>`; waitlist-web's `&image` tag:
     `1.0.0@sha256:<control digest>`; vnc-edge's tag: `1.0.0@sha256:<vnc-edge digest>` (step 3);
   - `waitlist.control.pod.vncPubkeys`: the `k1:<base64url>` line step 4a printed.

   Then check, from the repository root:
   ```sh
   grep -cE 'tag: 1\.0\.0@sha256:[0-9a-f]{64}$' kubernetes/apps/waitlist/waitlist/app/helmrelease.yaml   # 3
   grep -E '^ +vncPubkeys: k1:[A-Za-z0-9_-]{43}$' kubernetes/apps/waitlist/waitlist/app/helmrelease.yaml  # one line
   flux-local test --enable-helm --all-namespaces --path kubernetes/flux/cluster --sources flux-system   # as CI runs it
   ```
   The PR's flux-local check must be green before you merge (it fails while any placeholder is left).

7. **Level the app repo's copy** (no release needed): in the waitlist repo, on `main`, copy this
   `app/helmrelease.yaml` over `deploy/helmrelease.yaml`, set its `streamViewer:` and `offer:` lines back to
   `"off"`, check, and commit (`Fill in the deploy copy's 1.0.0 digests and checkout key`):
   ```sh
   cp <this repo>/kubernetes/apps/waitlist/waitlist/app/helmrelease.yaml deploy/helmrelease.yaml
   sed -E -i.orig 's/^( +(streamViewer|offer): )"(admins|everyone)"$/\1"off"/' deploy/helmrelease.yaml \
     && rm deploy/helmrelease.yaml.orig   # GNU and macOS sed alike
   WL_HOME_CLUSTER=<this repo, on this branch> uv run pytest tests/test_deploy.py -q   # all passed
   ```

**Rollback in Phase 0:** nothing in the cluster has changed. The 1Password fields, the lldap group and the
public packages can stay or be removed.

### Phase 1: merge

Merge this change (`<n>`: its PR) the repository's one way, a rebase: each of the branch's commits lands on main
(Phase 0 step 6 added one), and a rollback reverts them all. Then at once:

```sh
task github:pr:merge ID=<n>
task terraform:cf:plan      # one in-place change: the Rocket Loader rule's hosts become the two waitlist hosts
task terraform:cf:apply     # Rocket Loader and email obfuscation rewrite the HTML and break the CSP hashes
flux reconcile kustomization cluster-apps -n flux-system --with-source
task kubernetes:sync-secrets                                # authelia-secret gains WAITLIST_OAUTH_*, so Reloader restarts Authelia
flux get kustomizations -n waitlist                         # waitlist: Ready
kubectl -n waitlist get helmrelease waitlist                # Ready (the db hook created the database and ran 0001-0008)
kubectl -n waitlist get pods                                # waitlist-web, waitlist-control, waitlist-fetcher, 2 vnc-edge: Running
kubectl -n database get secret waitlist-web-role waitlist-control-role   # both exist
```

Flux creates the namespaces `waitlist` and `waitlist-browsers`, the empty `waitlist` database, the workloads and
the Authelia client. In the same pass cluster-apps deletes the Flux Kustomization `ferry-watch`, whose garbage
collection deletes its HelmRelease (a Helm uninstall), ExternalSecrets and backup CronJob. Check:

```sh
flux get kustomizations -A | grep ferry                   # nothing
kubectl -n ferry-watch get helmrelease,deployment,cronjob   # No resources found
```

Until Phase 2 drops the `ferrywatch` database, CNPG can't drop Ferry Watch's two login roles (they hold grants in
it) and lists them under `status.managedRolesStatus.cannotReconcile` on `cluster/postgres17`. That's expected and
doesn't hold up `waitlist_web` and `waitlist_control`.

**Rollback:** see [Rollback](#rollback).

### Phase S: smoke test (about 20 minutes)

1. Sign in at `https://waitlist.chestr.dev` (Authelia, password only). You are an admin (`bootstrapAdmins`).
2. **Push:** Account → turn alerts on for this device and allow notifications → "Send a test alert". It arrives.
3. **Admin:** the version line shows Web 1.0.0 and Control 1.0.0. The Providers card shows Buntzen Lake
   `Running`, "Offered to admins", Fetcher `OK`.
4. **A BC Ferries trip.** Add one. A `wl-<id>-g1` pod starts in `waitlist-browsers` and its first check
   completes: that proves the VAPs, quotas and egress. While it runs, check that the pod trusts the key
   waitlist-web signs with (no secret is printed):
   ```sh
   want=$(op read "op://kubernetes/waitlist/WAITLIST_CHECKOUT_KEY" | docker run --rm -i ghcr.io/mchestr/waitlist-control:1.0.0 python -c '
   import base64, sys
   from cryptography.hazmat.primitives.serialization import Encoding, PublicFormat
   from waitlist.web.config import checkout_key
   kid, key = checkout_key(sys.stdin.read().strip(), "k1")
   pub = base64.urlsafe_b64encode(key.public_key().public_bytes(Encoding.Raw, PublicFormat.Raw)).rstrip(b"=")
   print(kid + ":" + pub.decode())')
   have=$(kubectl -n waitlist-browsers get pods -l app.kubernetes.io/name=waitlist-browser \
     -o jsonpath='{.items[0].spec.containers[*].env[?(@.name=="WL_VNC_PUBKEYS")].value}')
   case ",$have," in *",$want,"*) echo "pubkey ok" ;; *) echo "MISMATCH: fix vncPubkeys" ;; esac
   ```
   It must print `pubkey ok`. If a sailing can be carted, also open the held cart's checkout once. Remove the trip.
5. **A Buntzen watch** (admins only while `offer: "admins"`: a member of `waitlist` who isn't an admin isn't
   offered Buntzen Lake). Add one for tomorrow. Before 07:00 it shows "On sale … 7:00 am"; after, it checks. Out
   of season the expected result is `no_inventory` with the out-of-season note, or plain `sold_out`: both prove
   DNS, the egress policies (including `egressDeny`), the resolver and the parser's envelope.
   - `site_changed` means Yodel's real answer differs from the parser's expectation. Capture it
     (`scripts/capture_yodel.py` in the waitlist repo), fix the parser and release 1.0.1, or set `offer: "off"`
     here (both copies) and carry on with BC Ferries only.
   - `network` or `timeout` (the fetcher logs `result=failed error=network` or `error=timeout`; Admin →
     Providers shows Fetcher `OK` and Last error `network` or `timeout`; the card says "Watching", then "Problem"
     after 3 failures) points at the fetcher's egress: DNS, or the `toFQDNs` rule. If DNS is the cause, drop the
     `egressDeny` block (the resolver check remains) and repeat.
   - `fetcher_unavailable` (the card says "Checks not running", Admin → Providers shows Fetcher `Down`) means
     waitlist-control can't reach the fetcher: its Service, waitlist-control's egress policy, or the fetcher pod
     (step 6).
6. **The fetcher:**
   ```sh
   kubectl -n waitlist get deployment waitlist-fetcher          # READY 1/1: its readiness probe is /readyz
   kubectl -n waitlist logs deploy/waitlist-fetcher | tail -n 5   # fetch provider=buntzen … result=ok
   kubectl -n waitlist port-forward deploy/waitlist-fetcher 8767:8767 >/dev/null & sleep 2
   curl -fsS localhost:8767/readyz; kill %1                     # ok
   ```

If something fails here and can't be fixed forward (a values change in both copies, or a 1.0.x release), roll
back now, before Phase 2.

### Phase 2: delete Ferry Watch's leftovers

Flux leaves some of Ferry Watch behind on purpose. `kubernetes/components/common/namespace.yaml` carries
`kustomize.toolkit.fluxcd.io/prune: disabled`, so the `ferry-watch` Namespace stays; `ferry-watch-browsers`
carries `helm.sh/resource-policy: keep`, so the uninstall left it (with its bare browser pods and its default-deny
NetworkPolicy); and nothing in git owns the database. The commands are safe to repeat.

1. **The backup CronJob, before its database.** The Kustomization's garbage collection normally deleted it; if
   it is still there, it would fail every 4 hours from step 4 on:
   ```sh
   kubectl -n ferry-watch delete cronjob ferrywatch-pg-backups --ignore-not-found --cascade=foreground
   ```
2. **The cluster-scoped objects** Ferry Watch's HelmRelease rendered. The Helm uninstall normally deleted them.
   They are exactly these: three ValidatingAdmissionPolicies and their bindings, two ClusterRoles and their
   bindings, and a PriorityClass. Its CiliumNetworkPolicies (`fw-browser-egress`, `fw-browser-hold-egress`, and
   one per workload) are namespaced and go with the namespaces in step 3.
   ```sh
   kubectl delete validatingadmissionpolicybinding fw-browser-pod fw-browser-pod-lock fw-ns-objects --ignore-not-found
   kubectl delete validatingadmissionpolicy fw-browser-pod fw-browser-pod-lock fw-ns-objects --ignore-not-found
   kubectl delete clusterrolebinding ferry-watch-control-tokenreview ferry-watch-control-nodes --ignore-not-found
   kubectl delete clusterrole ferry-watch-control-tokenreview ferry-watch-control-nodes --ignore-not-found
   kubectl delete priorityclass ferry-browser --ignore-not-found
   ```
3. **The namespaces:**
   ```sh
   kubectl delete namespace ferry-watch ferry-watch-browsers --ignore-not-found --wait
   ```
4. **The database and its owner role** (the owner was made by Ferry Watch's db hook, not by CNPG):
   ```sh
   pg -v ON_ERROR_STOP=1 -c 'DROP DATABASE IF EXISTS ferrywatch WITH (FORCE)' -c 'DROP ROLE IF EXISTS ferrywatch'
   ```
5. **The two login roles.** CNPG drops `ferrywatch_web` and `ferrywatch_control` on its next pass, as the
   `ensure: absent` entries in `cluster17.yaml` ask:
   ```sh
   pg -At -c "SELECT rolname FROM pg_roles WHERE rolname LIKE 'ferrywatch%'"   # nothing, within a few minutes
   kubectl -n database get cluster postgres17 -o jsonpath='{.status.managedRolesStatus.cannotReconcile}'   # empty
   ```
   Still listed after 10 minutes? Drop them yourself; CNPG then finds them absent:
   `pg -v ON_ERROR_STOP=1 -c 'DROP ROLE IF EXISTS ferrywatch_web' -c 'DROP ROLE IF EXISTS ferrywatch_control'`.
6. **Check** that nothing is left:
   ```sh
   kubectl get namespace ferry-watch ferry-watch-browsers                 # NotFound, twice
   kubectl get validatingadmissionpolicies,validatingadmissionpolicybindings,clusterroles,clusterrolebindings,priorityclasses -o name \
     | grep -E '/(fw-|ferry)'                                             # prints nothing
   pg -At -c "SELECT datname FROM pg_database WHERE datname = 'ferrywatch'"   # nothing
   ```
7. **1Password and lldap.** Remove Ferry Watch's fields and item, then delete the lldap group `ferry-watch`:
   ```sh
   op item edit authelia --vault kubernetes 'FERRY_WATCH_OAUTH_CLIENT_ID[delete]' \
     'FERRY_WATCH_OAUTH_CLIENT_SECRET[delete]' 'FERRY_WATCH_OAUTH_CLIENT_SECRET_HASH[delete]' >/dev/null
   op item edit cloudnative-pg --vault kubernetes 'ferrywatch_postgres_username[delete]' \
     'ferrywatch_postgres_password[delete]' 'ferrywatch_web_password[delete]' 'ferrywatch_control_password[delete]' >/dev/null
   op item delete ferry-watch --vault kubernetes
   ```
   The old backup dumps (`ferrywatch` in `nebula.chestr.dev:/var/nfs/shared/cluster/apps/postgres-backup-local`)
   can go whenever you like.
8. **Follow-up commit**, once step 5 shows no role: delete the two `ensure: absent` entries for `ferrywatch_web`
   and `ferrywatch_control` (and their comment) from `database/cloudnative-pg/cluster/cluster17.yaml`, with
   `chore(cloudnative-pg): drop the absent Ferry Watch roles`. Removing them sooner would leave the roles in place:
   CNPG ignores a role that isn't listed.

### Rollback

- **Before Phase 2:** revert every commit this change put on main, newest first, in one PR. Reverting only one
  stops in conflicts, or just puts the placeholders back. `<n>` is this change's PR:
  ```sh
  M=$(gh api repos/mchestr/home-cluster/pulls/<n> --jq .merge_commit_sha)   # the last of its commits on main
  K=$(gh api repos/mchestr/home-cluster/pulls/<n> --jq .commits)            # how many it put there
  git fetch origin && git switch -c revert-waitlist origin/main
  git log --oneline "$M~$K..$M"      # exactly this change's commits
  git revert --no-edit "$M~$K..$M"   # one revert commit each, newest first
  git push -u origin revert-waitlist && gh pr create -R mchestr/home-cluster --fill
  ```
  Merge that PR (`task github:pr:merge ID=<its number>`), then `task terraform:cf:apply` and
  `flux reconcile kustomization cluster-apps -n flux-system --with-source`. Ferry Watch comes back as it was: its
  namespaces, database, roles and 1Password fields are all still there, and its images still exist on GHCR under
  the old names (`ghcr.io/mchestr/ferry-watch-*`). The revert deletes the `waitlist` Kustomization, whose garbage
  collection uninstalls Waitlist; delete what that leaves (the reverted `cluster17.yaml` no longer lists
  Waitlist's roles, so CNPG leaves them to you):
  ```sh
  # The uninstall first: deleting the namespace under it would take Helm's release Secrets, and Helm would then
  # leave the cluster-scoped objects behind.
  kubectl -n waitlist wait --for=delete kustomization/waitlist helmrelease/waitlist --timeout=10m
  kubectl delete namespace waitlist waitlist-browsers --wait   # prune: disabled, and helm.sh/resource-policy: keep
  pg -v ON_ERROR_STOP=1 -c 'DROP DATABASE IF EXISTS waitlist WITH (FORCE)' -c 'DROP ROLE IF EXISTS waitlist' \
    -c 'DROP ROLE IF EXISTS waitlist_web' -c 'DROP ROLE IF EXISTS waitlist_control'
  # The cluster-scoped objects the HelmRelease rendered: the uninstall normally removed them, so these find nothing.
  kubectl delete validatingadmissionpolicybinding wl-browser-pod wl-browser-pod-lock wl-ns-objects --ignore-not-found
  kubectl delete validatingadmissionpolicy wl-browser-pod wl-browser-pod-lock wl-ns-objects --ignore-not-found
  kubectl delete clusterrolebinding waitlist-control-tokenreview waitlist-control-nodes --ignore-not-found
  kubectl delete clusterrole waitlist-control-tokenreview waitlist-control-nodes --ignore-not-found
  kubectl delete priorityclass waitlist-browser --ignore-not-found
  kubectl get validatingadmissionpolicies,validatingadmissionpolicybindings,clusterroles,clusterrolebindings,priorityclasses -o name \
    | grep -E '/(wl-|waitlist)'                                # prints nothing
  ```
- **After Phase 2** the same revert brings Ferry Watch back empty, once what Phase 2 deleted exists again. Ferry
  Watch's own README has the steps (`git show "$M~$K:kubernetes/apps/ferry-watch/ferry-watch/README.md"`, with `M`
  and `K` as above), with three changes:
  1. **1Password and lldap.** Phase 2 step 7 deleted the item `ferry-watch`, so that README's `op item edit
     ferry-watch` would fail: create the item instead, with new keys from Ferry Watch's last image. Then add the
     `authelia` and `cloudnative-pg` fields as its steps 1 and 2 do, and create the lldap group `ferry-watch`.
     ```sh
     if op item get ferry-watch --vault kubernetes >/dev/null 2>&1; then
       echo "item ferry-watch exists: delete it first"
     else
       KEYS="$(docker run --rm ghcr.io/mchestr/ferry-watch-control:0.7.1 ferry-web keys)"
       case "$KEYS" in
         *'FERRY_WATCH_CHECKOUT_KEY=k1:'?*'FERRY_WATCH_VAPID_KEY='?*)
           op item create --vault kubernetes --category password --title ferry-watch \
             "FERRY_WATCH_CHECKOUT_KEY[password]=$(printf '%s\n' "$KEYS" | sed -n 's/^FERRY_WATCH_CHECKOUT_KEY=//p')" \
             "FERRY_WATCH_VAPID_KEY[password]=$(printf '%s\n' "$KEYS" | sed -n 's/^FERRY_WATCH_VAPID_KEY=//p')" >/dev/null \
             && printf '%s\n' "$KEYS" | tail -n 1 ;;  # k1:<base64url>, the checkout key's public half: keep it for 3.
         *) echo "no keys: stop" ;;
       esac
       unset KEYS
     fi
     ```
  2. **The revert.** If Phase 2 step 8's commit has landed, revert it first. It deleted the `ensure: absent`
     lines that this change's own revert edits, so `git revert "$M~$K..$M"` alone stops in a conflict in
     `cluster17.yaml`. In place of the `git revert` line above, and before its `git push`:
     ```sh
     S=$(git log --format=%H -1 -F --grep='drop the absent Ferry Watch roles' origin/main)   # empty if it hasn't
     [ -z "$S" ] || git revert --no-edit "$S"
     git revert --no-edit "$M~$K..$M"
     ```
  3. **The checkout key's public half.** The reverted `helmrelease.yaml` has the deleted key's, and browser pods
     would refuse every checkout ticket. Before pushing, put in the `k1:` line that 1 printed, and commit it:
     ```sh
     PUB='k1:<the line 1 printed>'
     f=kubernetes/apps/ferry-watch/ferry-watch/app/helmrelease.yaml
     sed -E -i.orig "s/^( +vncPubkeys: )k1:[A-Za-z0-9_-]{43}\$/\\1$PUB/" "$f" && rm "$f.orig"
     grep -E '^ +vncPubkeys: k1:' "$f"   # one line, with the new key
     git commit -am 'fix(ferry-watch): the checkout key re-created after the rollback'
     ```
  Then push and open the PR, merge it and clean up, as in the bullet above.
