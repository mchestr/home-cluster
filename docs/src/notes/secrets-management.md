# Secrets Management

How I handle secrets using External Secrets and 1Password.

## How It Works

```
1Password -> 1Password Connect -> External Secrets Operator -> Kubernetes Secrets
```

All my secrets live in 1Password. The External Secrets Operator pulls them into the cluster automatically.

## Adding a New Secret

### 1. Create in 1Password

Add a new item to 1Password with the fields you need. The item name should match what you want the Kubernetes secret to be called.

### 2. Create an ExternalSecret

Add this to your app's directory:

```yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: my-app-secret
  namespace: default
spec:
  refreshInterval: 1h
  secretStoreRef:
    kind: ClusterSecretStore
    name: onepassword-connect
  target:
    name: my-app-secret
    creationPolicy: Owner
  dataFrom:
    - extract:
        key: my-1password-item
```

If you only need specific fields:

```yaml
spec:
  data:
    - secretKey: api-key
      remoteRef:
        key: my-1password-item
        property: api_key
```

### 3. Commit and Let Flux Do Its Thing

Commit to git and Flux will create the secret. Or apply manually:

```bash
kubectl apply -f externalsecret.yaml
```

Verify it worked:

```bash
kubectl get secret -n <namespace> <name>
kubectl get externalsecret -n <namespace> <name>
```

## Force Sync All Secrets

If you updated something in 1Password and don't want to wait for the refresh interval:

```bash
task kubernetes:sync-secrets
```

Or for a single secret:

```bash
kubectl -n <namespace> annotate externalsecret <name> force-sync="$(date +%s)" --overwrite
```

## Troubleshooting

### ExternalSecret Shows Error

Check whats wrong:

```bash
kubectl describe externalsecret -n <namespace> <name>
```

Common issues:

| Error | Problem | Fix |
|-------|---------|-----|
| `item not found` | Item doesn't exist in 1Password | Create it |
| `field not found` | Requested field missing | Add the field |
| `connect error` | 1Password Connect is down | Check the pod |

### 1Password Connect Issues

```bash
# Check pod status
kubectl get pods -n external-secrets -l app=onepassword-connect

# Check logs
kubectl logs -n external-secrets -l app=onepassword-connect
```

### Secret Not Updating

Secrets refresh based on `refreshInterval`. Force it:

```bash
task kubernetes:sync-secrets
```

## Rotating Secrets

1. Update the value in 1Password
2. Force sync: `kubectl -n <ns> annotate externalsecret <name> force-sync="$(date +%s)" --overwrite`
3. Restart the app to pick up the new value: `kubectl rollout restart deployment -n <ns> <deployment>`

## Emergency Access

If External Secrets is broken and you need a secret NOW:

```bash
kubectl create secret generic <name> -n <namespace> --from-literal=<key>=<value>
```

Just remember this will get overwritten when External Secrets starts working again. Update 1Password if you want changes to stick.
