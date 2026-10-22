# Troubleshooting

Common issues and how to fix them.

## Quick Diagnostics

```bash
# Node status
kubectl get nodes -o wide

# All pods
kubectl get pods -A

# Recent events
kubectl get events -A --sort-by='.lastTimestamp' | tail -20

# Flux status
flux get all -A | grep -i false
```

## Pods Not Starting

### Stuck in Pending

```bash
kubectl describe pod -n <namespace> <pod>
```

| Cause | Fix |
|-------|-----|
| Not enough resources | Scale down other stuff or add capacity |
| Node selector doesn't match | Check node labels |
| PVC not bound | Check storage class and PVC |
| Taints blocking it | Add tolerations |

### Stuck in ContainerCreating

```bash
kubectl describe pod -n <namespace> <pod>
kubectl get events -n <namespace> --field-selector involvedObject.name=<pod>
```

| Cause | Fix |
|-------|-----|
| Image pull failed | Check image name and registry creds |
| Volume mount failed | Check PVC and CSI driver |
| Secret not found | Check ExternalSecret synced |

### CrashLoopBackOff

```bash
kubectl logs -n <namespace> <pod> --previous
```

Usually the app is crashing - check logs for stack traces.

## Clean Up Failed Pods

```bash
task kubernetes:cleanse-pods
```

This removes pods in Failed, Pending, Succeeded, Completed, NodeStatusUnknown, or Error states.

## Flux Issues

### HelmRelease Stuck

```bash
flux get hr -A | grep False
kubectl describe helmrelease -n <namespace> <release>
```

Restart it:

```bash
task kubernetes:hr:restart
```

Or manually:

```bash
flux suspend hr -n <namespace> <release>
flux resume hr -n <namespace> <release>
```

### Nothing is Syncing

Force a reconcile:

```bash
task kubernetes:reconcile
```

## Node Issues

### Node NotReady

```bash
kubectl describe node <node>
talosctl -n <node> services
talosctl -n <node> dmesg | tail -50
```

| Cause | Fix |
|-------|-----|
| Kubelet not running | `talosctl -n <node> service kubelet restart` |
| Network issues | Check CNI pods |
| Disk pressure | Check disk usage |

### Node Unreachable

Try a reboot:

```bash
task talos:reboot-node NODE=<node>
```

If that doesn't work, power cycle it via IPMI/KVM.

## Network Issues

### Services Unreachable

```bash
# Cilium status
kubectl -n kube-system exec -it ds/cilium -- cilium status

# BGP peers
kubectl -n kube-system exec -it ds/cilium -- cilium bgp peers

# LoadBalancer IPs
kubectl get svc -A | grep LoadBalancer
```

### DNS Broken

```bash
# Check CoreDNS
kubectl get pods -n kube-system -l k8s-app=kube-dns

# Test resolution
kubectl run -it --rm debug --image=busybox -- nslookup kubernetes.default
```

## Certificate Issues

```bash
kubectl get certificate -A
kubectl describe certificate -n <namespace> <name>
kubectl get certificaterequest -A
```

| Cause | Fix |
|-------|-----|
| DNS challenge failing | Check Cloudflare creds |
| Rate limited | Wait and retry |
| Invalid domain | Check certificate spec |

## App Issues

### Seerr: Plex User Cannot Sign In

A user signs in at `requests.chestr.dev` with Plex, and Seerr refuses them. Seerr checks the user against the Plex share list of the owner account. The user must be on that list with the same email as their Plex account.

Use plex-manager (the `subs` app at `subs.chestr.dev`) to find the user's real email and Plex access. Do not copy user emails or names into Git, issues or chat logs.

#### Check

1. Find the failed attempt in the Seerr log:

   ```bash
   kubectl -n media logs deploy/jellyseerr | grep -i "sign-in\|user access"
   ```

2. Find the `Failed sign-in attempt by Plex user without access to the media server` line. Note its `plexUsername`, `plexId` and `email`.
3. Look for `This user does not exist on the main Plex account's shared list` at the same time. This line shows that the user is not on the share list.
4. Look for `[Plex Refresh Token]: Failed to ping token` with status 401. This line shows that the Seerr admin token is bad.
5. In plex-manager, open Admin → Users and select "Import Plex Users" to refresh the list.
6. Search for the user by name or Plex username.
7. Open the user and compare the email with the `email` in the Seerr log.
8. Check the Plex access status of the user in plex-manager.

#### Fix

| Result of the check | Fix |
|---|---|
| The emails are different | Share the Plex server again with the email of the user's Plex account |
| The user has no Plex access | Share the Plex server with the user |
| The Seerr log shows the 401 token error | Sign in to Plex again in Seerr Settings → Plex |

1. Tell the user to accept the Plex invite.
2. In Seerr, open Settings → Users and select "Import Plex Users".
3. Tell the user to sign in again.
4. Look at the Seerr log again for a new failed attempt.

## Debug Tools

### Node Shell

```bash
task kubernetes:node-shell NODE=<node>
```

### NFS Debug Pod

```bash
task kubernetes:nfs-pod NS=<namespace>
```

### Browse a PVC

```bash
task kubernetes:browse-pvc NS=<namespace> CLAIM=<pvc-name>
```

### Tail Logs

```bash
stern -n <namespace> -l app.kubernetes.io/name=<app>
```

## When All Else Fails

1. Check external monitoring (HealthChecks.io, UptimeRobot)
2. Check recent git commits - did something change?
3. Check the component docs ([Talos](https://www.talos.dev/docs/), [Flux](https://fluxcd.io/docs/), [Cilium](https://docs.cilium.io/), [Rook](https://rook.io/docs/rook/latest/))
4. Ask in the [Kubernetes @Home Discord](https://discord.gg/k8s-at-home)
