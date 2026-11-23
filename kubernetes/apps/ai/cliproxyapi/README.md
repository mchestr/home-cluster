# CLIProxyAPI

CLIProxyAPI is the OpenAI-compatible LLM proxy for memini and Silo. Its models are aliases in the `config.yaml` that `app/externalsecret.yaml` renders:

| Alias | Upstream | Client |
|---|---|---|
| `memini-chat` | OpenRouter `qwen/qwen3-14b` | memini |
| `silo-translate` | Anthropic API `claude-opus-5-5` | Silo |
| `silo-translate-fast` | Anthropic API `claude-haiku-5-5` | Silo (optional) |

After the Codex device login (below), the ChatGPT subscription models (for example `gpt-5.5`) are also available.

Embeddings do not go through the proxy, because CLIProxyAPI has no `/v1/embeddings` route. memini and Silo call `text-embeddings` directly.

## Security

- The proxy has no HTTPRoute.
- The Cilium policy admits only memini and Silo on port 8317.
- The Cilium policy permits outbound traffic only to kube-dns, `openrouter.ai`, `api.anthropic.com`, `chatgpt.com` and `auth.openai.com`.
- The Management API and its web panel are off.
- Each client has its own key in `access.api-keys`. Any key can call every model.
- Claude request cloaking (the Claude Code CLI disguise) is off, so Anthropic gets the client's own system prompt.

If you add a provider, add its hosts to `app/ciliumnetworkpolicy.yaml`.

## 1Password item

The item `cliproxyapi` has these fields:

| Field | Value |
|---|---|
| `OPENROUTER_API_KEY` | OpenRouter API key |
| `ANTHROPIC_API_KEY` | Anthropic API key |
| `MEMINI_CLIENT_KEY` | Random key, for example `openssl rand -hex 32` |
| `SILO_CLIENT_KEY` | Random key, for example `openssl rand -hex 32` |

To revoke a client, change its field. Reloader restarts the proxy when the Secret changes.

## Silo configuration

Silo keeps its AI configuration in its database (Admin > Integrations > AI).

1. Add an OpenAI-compatible provider for text with the base URL `http://cliproxyapi.ai.svc.cluster.local:8317/v1` and the key `SILO_CLIENT_KEY`.
2. Set the text model to `silo-translate`.
3. Add an OpenAI-compatible provider for embeddings with the base URL `http://text-embeddings.ai.svc.cluster.local:8080/v1` and any key.
4. Reset the recommendation embeddings. The embedding lock includes the base URL, so Silo refuses the new provider until you reset.
5. Set the embedding model to `silo-embed` and let Silo embed the catalog again.

## Codex login (optional)

1. Start the device login in the pod:

   ```sh
   kubectl -n ai exec -it deploy/cliproxyapi -- /CLIProxyAPI/CLIProxyAPI --config /config/config.yaml --local-model --codex-device-login
   ```

2. Open the URL that the command shows, and type the code.
3. Sign in with the ChatGPT account.
4. Wait for the command to save the credential and stop. The server loads the new file without a restart.

The credential is a file in the `cliproxyapi` PVC (`/data/auths`). The PVC has no VolSync backup. If you lose the PVC, do the login again.

## Test

1. Forward the port to your computer: `kubectl -n ai port-forward svc/cliproxyapi 8317:8317`.
2. In a second shell, send a request:

   ```sh
   KEY=$(op read op://kubernetes/cliproxyapi/MEMINI_CLIENT_KEY)
   curl -s http://localhost:8317/v1/chat/completions \
     -H "Authorization: Bearer $KEY" -H 'Content-Type: application/json' \
     -d '{"model":"memini-chat","messages":[{"role":"user","content":"Say hello"}]}'
   ```

The port-forward goes through the kubelet, so the Cilium ingress rule does not apply to it.
