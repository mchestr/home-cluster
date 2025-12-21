# Application Deployment

How to deploy apps using Flux.

## Repo Structure

```
kubernetes/
├── flux/                    # Flux config
├── components/             # Reusable components
└── apps/                   # Applications by namespace
    ├── cert-manager/
    ├── database/
    ├── default/
    ├── external-secrets/
    ├── flux-system/
    ├── kube-system/
    ├── media/
    ├── networking/
    ├── observability/
    ├── openebs-system/
    ├── rook-ceph/
    ├── system-upgrade/
    └── volsync-system/
```

## App Structure

Each app follows this pattern:

```
apps/<namespace>/<app-name>/
├── ks.yaml                 # Flux Kustomization
└── app/
    ├── kustomization.yaml
    ├── helmrelease.yaml
    └── externalsecret.yaml # If needed
```

## Deploying a New App

### 1. Create the Directory

```bash
mkdir -p kubernetes/apps/<namespace>/<app-name>/app
```

### 2. Create the Flux Kustomization

`ks.yaml`:

```yaml
---
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: &app my-app
  namespace: flux-system
spec:
  targetNamespace: default
  commonMetadata:
    labels:
      app.kubernetes.io/name: *app
  path: ./kubernetes/apps/default/my-app/app
  prune: true
  sourceRef:
    kind: GitRepository
    name: flux-system
  wait: false
  interval: 30m
  retryInterval: 1m
  timeout: 5m
```

### 3. Create the HelmRelease

`app/helmrelease.yaml`:

```yaml
---
apiVersion: helm.toolkit.fluxcd.io/v2
kind: HelmRelease
metadata:
  name: my-app
spec:
  interval: 30m
  chart:
    spec:
      chart: my-app
      version: 1.0.0
      sourceRef:
        kind: HelmRepository
        name: some-repo
        namespace: flux-system
  install:
    remediation:
      retries: 3
  upgrade:
    cleanupOnFail: true
    remediation:
      strategy: rollback
      retries: 3
  values:
    # your values here
```

### 4. Create the Kustomization

`app/kustomization.yaml`:

```yaml
---
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - helmrelease.yaml
```

### 5. Add to Namespace

Add your app to `kubernetes/apps/<namespace>/kustomization.yaml`:

```yaml
resources:
  - ./my-app/ks.yaml
```

### 6. Commit and Push

```bash
git add kubernetes/apps/<namespace>/<app-name>
git commit -m "feat: add my-app"
git push
```

Flux picks it up automatically.

## Managing Apps

### Force Reconcile

```bash
task kubernetes:reconcile
```

### Check Status

```bash
flux get hr -n <namespace> <app>
flux get ks <app>
kubectl get pods -n <namespace> -l app.kubernetes.io/name=<app>
```

### Suspend/Resume

```bash
flux suspend ks <app>
flux suspend hr -n <namespace> <app>

flux resume ks <app>
flux resume hr -n <namespace> <app>
```

## Adding Storage

For Ceph storage, add a PVC:

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: my-app
spec:
  accessModes: ["ReadWriteOnce"]
  storageClassName: ceph-block
  resources:
    requests:
      storage: 10Gi
```

## Adding Backups

Create a ReplicationSource for Volsync:

```yaml
apiVersion: volsync.backube/v1alpha1
kind: ReplicationSource
metadata:
  name: my-app
spec:
  sourcePVC: my-app
  trigger:
    schedule: "0 0 * * *"  # Daily
  restic:
    repository: my-app-restic-secret
    retain:
      daily: 7
      weekly: 4
```

## Ingress

For external access, use Gateway API:

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: my-app
spec:
  parentRefs:
    - name: external
      namespace: networking
  hostnames: ["my-app.example.com"]
  rules:
    - backendRefs:
        - name: my-app
          port: 80
```

For internal only, use `internal` instead of `external`.

## Renovate

Renovate watches for updates and creates PRs automatically. Just review and merge them:

```bash
task github:pr:list
task github:pr:merge ID=<pr>
```
