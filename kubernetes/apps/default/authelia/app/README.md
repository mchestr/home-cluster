# Authelia OAuth2 Secrets

## Populate Secrets for a New App

Generate an OIDC client id, secret and secret hash with the Authelia version the cluster runs (the tag in `helmrelease.yaml`), and store them in the `authelia` item in 1Password. The generated values are passed straight to `op`; they never reach the screen or your shell history.

```bash
export APP=MYAPP              # upper-case prefix used in externalsecret.yaml
AUTHELIA=authelia/authelia:4.39.28

CLIENT_ID="$(docker run --rm "$AUTHELIA" authelia crypto rand --length 72 --charset rfc3986 | awk '/^Random Value:/ {print $3}')"
SECRET_OUT="$(docker run --rm "$AUTHELIA" authelia crypto hash generate argon2 --random --random.length 64 --random.charset alphanumeric)"
CLIENT_SECRET="$(printf '%s\n' "$SECRET_OUT" | awk '/^Random Password:/ {print $3}')"
CLIENT_SECRET_HASH="$(printf '%s\n' "$SECRET_OUT" | awk '/^Digest:/ {print $2}')"
case "$CLIENT_SECRET_HASH" in '$argon2id$'*) echo "ok" ;; *) echo "no hash: stop"; exit 1 ;; esac

op item edit authelia --vault kubernetes \
  "${APP}_OAUTH_CLIENT_ID[password]=$CLIENT_ID" \
  "${APP}_OAUTH_CLIENT_SECRET[password]=$CLIENT_SECRET" \
  "${APP}_OAUTH_CLIENT_SECRET_HASH[password]=$CLIENT_SECRET_HASH" >/dev/null
unset CLIENT_ID SECRET_OUT CLIENT_SECRET CLIENT_SECRET_HASH
```

Then add the three keys to `externalsecret.yaml`, the client to `resources/configuration.yaml` (Authelia gets the `_HASH`, the app gets the plain secret), and an access rule or `authorization_policies` entry for the groups that may use it. `kubernetes/apps/waitlist/waitlist/app/` is a complete worked example.
