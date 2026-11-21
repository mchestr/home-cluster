# CLIProxyAPI

CLIProxyAPI turns the ChatGPT subscription (Codex OAuth login) into an OpenAI-compatible API. It is a test. Only litellm calls it, through the `codex-chat` model. It has no HTTPRoute, and a NetworkPolicy admits only the litellm pods.

The Codex credential is a file in the `cliproxyapi` PVC (`/data/auths`). The PVC has no VolSync backup. If you lose the PVC, do the login again.

## Before you merge

1. Generate a random key: `openssl rand -hex 32`.
2. Add it as the field `CLIPROXYAPI_API_KEY` in the 1Password item `litellm`.

WARNING: Add the field before Flux applies this change. If the field is missing, the `litellm` ExternalSecret fails and litellm stops getting secret updates.

## Log in to Codex

1. Start the device login in the pod:

   ```sh
   kubectl -n ai exec -it deploy/cliproxyapi -- /CLIProxyAPI/CLIProxyAPI --config /config/config.yaml --codex-device-login
   ```

2. Open the URL that the command shows, and type the code.
3. Sign in with the ChatGPT account.
4. Wait for the command to save the credential and stop.
5. Read the logs: `kubectl -n ai logs deploy/cliproxyapi`. The server loads the new auth file without a restart.

## Test

1. Forward the litellm port to your computer: `kubectl -n ai port-forward svc/litellm 4000:4000`.
2. In a second shell, send a request through litellm:

   ```sh
   KEY=$(kubectl -n ai get secret litellm-secret -o jsonpath='{.data.LITELLM_MASTER_KEY}' | base64 -d)
   curl -s http://localhost:4000/v1/chat/completions \
     -H "Authorization: Bearer $KEY" -H 'Content-Type: application/json' \
     -d '{"model":"codex-chat","messages":[{"role":"user","content":"Say hello"}]}'
   ```

3. To use it in Silo or memini, set the model name to `codex-chat`.

## Remove

1. Delete `kubernetes/apps/ai/cliproxyapi/`.
2. Remove `./cliproxyapi/ks.yaml` from `kubernetes/apps/ai/kustomization.yaml`.
3. Delete `codex-chat.yaml` from the litellm models.
4. Remove `CLIPROXYAPI_API_KEY` from the litellm ExternalSecret.
