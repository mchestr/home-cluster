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
stern -n <namespace> -l app=<app>
```

## When All Else Fails

1. Check external monitoring (HealthChecks.io, UptimeRobot)
2. Check recent git commits - did something change?
3. Check the component docs ([Talos](https://www.talos.dev/docs/), [Flux](https://fluxcd.io/docs/), [Cilium](https://docs.cilium.io/), [Rook](https://rook.io/docs/rook/latest/))
4. Ask in the [Kubernetes @Home Discord](https://discord.gg/k8s-at-home)
