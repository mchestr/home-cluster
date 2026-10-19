# Application Deployment

How to deploy apps using Flux. The short version is in [`AGENTS.md`](https://github.com/mchestr/home-cluster/blob/main/AGENTS.md); this page walks through it.

## Repo Structure

```
kubernetes/
├── flux/
│   ├── cluster/ks.yaml        # Entry point: loads meta, then every namespace under apps/
│   └── meta/                  # CRDs and shared Helm/OCI repositories
├── components/                # Reusable Kustomize components (common, volsync, cnpg, dragonfly)
└── apps/<namespace>/          # One directory per namespace: actions-runner-system, ai, cert-manager,
    │                          # database, default, external-secrets, flux-system,
    │                          # kube-system, media, networking, observability, openebs-system,
    │                          # rook-ceph, system-upgrade, volsync-system, waitlist
    ├── kustomization.yaml     # Lists each app's ks.yaml in the namespace
    └── <app>/
        ├── ks.yaml            # Flux Kustomization: dependsOn, components, postBuild vars
        └── app/
            ├── kustomization.yaml
            ├── helmrelease.yaml
            ├── externalsecret.yaml   # If needed
            └── resources/            # Config files mounted from ConfigMaps, if any
```

## Deploying a New App

### 1. The Flux Kustomization

`kubernetes/apps/<namespace>/<app>/ks.yaml`. The Kustomization lives in the app's namespace and deploys there with `targetNamespace`. `dependsOn` lists what must exist first (`onepassword-store` for anything with an ExternalSecret, `rook-ceph-cluster` for a PVC, `cloudnative-pg-cluster` for a database). `components` add storage, backups and databases; `postBuild.substitute` feeds them.

```yaml
---
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: &app my-app
  namespace: &namespace default
spec:
  commonMetadata:
    labels:
      app.kubernetes.io/name: *app
  components:
    - ../../../../components/volsync      # PVC named after the app + nightly restic backup to R2
  dependsOn:
    - name: onepassword-store
      namespace: external-secrets
    - name: rook-ceph-cluster
      namespace: rook-ceph
  interval: 30m
  path: ./kubernetes/apps/default/my-app/app
  postBuild:
    substitute:
      APP: *app
      VOLSYNC_CAPACITY: 10Gi
  prune: true
  retryInterval: 1m
  sourceRef:
    kind: GitRepository
    name: flux-system
    namespace: flux-system
  targetNamespace: *namespace
  timeout: 5m
  wait: false
```

Components and their variables:

| Component | Adds | Variables |
|---|---|---|
| `volsync` | PVC `${APP}` + ReplicationSource/Destination to Cloudflare R2 | `APP`, `VOLSYNC_CAPACITY` (5Gi), `VOLSYNC_SCHEDULE`, `VOLSYNC_CACHE_CAPACITY`, `VOLSYNC_STORAGECLASS`, `VOLSYNC_ACCESSMODES`, `VOLSYNC_CLAIM`, `APP_UID`/`APP_GID` (must match the container user for the restore to be readable) |
| `cnpg` | Database on the CloudNative-PG cluster, `${APP}-pguser-secret`, `${APP}-initdb-secret`, backup CronJob | `APP`, `CNPG_NAME` (postgres17). Create the credentials in 1Password first: `kubernetes/components/cnpg/README.md` |
| `dragonfly` | A Dragonfly (Redis-compatible) instance `${APP}-dragonfly` | `APP`, `DRAGONFLY_REPLICAS` (1) |

### 2. The HelmRelease

Nearly every app uses the shared `app-template` chart through `chartRef`. The things the rest of the cluster relies on:

- **Probes on a real health endpoint.** A failed upgrade is rolled back only if the pod fails its probes before the Helm timeout, and app-template enables no probes by default.
- **Security context**: `runAsNonRoot` with a fixed UID/GID at the pod level, `allowPrivilegeEscalation: false`, `readOnlyRootFilesystem: true` and `capabilities.drop: [ALL]` on the container, unless the app needs a device.
- **Resources**: a CPU request and a memory limit.
- **Secrets** via `envFrom: secretRef` from the ExternalSecret, with `reloader.stakater.com/auto: "true"` on the controller so rotated secrets restart the pod.
- **Routes** under `route`, default gateway `envoy-internal`.

```yaml
---
apiVersion: helm.toolkit.fluxcd.io/v2
kind: HelmRelease
metadata:
  name: &app my-app
spec:
  interval: 30m
  chartRef:
    kind: OCIRepository
    name: app-template
  maxHistory: 2
  values:
    controllers:
      my-app:
        annotations:
          reloader.stakater.com/auto: "true"
        containers:
          app:
            image:
              repository: ghcr.io/example/my-app
              tag: 1.2.3
            envFrom:
              - secretRef:
                  name: my-app-secret
            probes:
              liveness: &probes
                enabled: true
                custom: true
                spec:
                  httpGet:
                    path: /healthz
                    port: &port 8080
                  periodSeconds: 10
                  timeoutSeconds: 3
                  failureThreshold: 3
              readiness: *probes
            securityContext:
              allowPrivilegeEscalation: false
              readOnlyRootFilesystem: true
              capabilities: { drop: ["ALL"] }
            resources:
              requests:
                cpu: 10m
              limits:
                memory: 256Mi
    defaultPodOptions:
      securityContext:
        runAsNonRoot: true
        runAsUser: 1000
        runAsGroup: 1000
        fsGroup: 1000
        fsGroupChangePolicy: OnRootMismatch
    service:
      app:
        controller: *app
        ports:
          http:
            port: *port
    route:
      app:
        hostnames: ["{{ .Release.Name }}.chestr.dev"]
        parentRefs:
          - name: envoy-internal
            namespace: networking
            sectionName: https
        rules:
          - backendRefs:
              - name: *app
                port: *port
    persistence:
      config:
        existingClaim: *app       # created by the volsync component
```

Install/upgrade remediation is not set per app: `kubernetes/flux/cluster/ks.yaml` patches every HelmRelease so a failed upgrade is rolled back to the last good release. If the app runs database migrations on upgrade, opt out of rollback instead:

```yaml
spec:
  upgrade:
    strategy:
      name: RetryOnFailure
```

### 3. Secrets

Put the values in a 1Password item and add an `ExternalSecret` (see [secrets management](secrets-management.md)):

```yaml
---
apiVersion: external-secrets.io/v1
kind: ExternalSecret
metadata:
  name: my-app
spec:
  secretStoreRef:
    kind: ClusterSecretStore
    name: onepassword
  target:
    name: my-app-secret
    creationPolicy: Owner
    template:
      engineVersion: v2
      data:
        API_KEY: "{{ .MY_APP_API_KEY }}"
  dataFrom:
    - extract:
        key: my-app
```

### 4. The Kustomization and the namespace list

`app/kustomization.yaml` lists the files; then add `./my-app/ks.yaml` to `kubernetes/apps/<namespace>/kustomization.yaml`. New namespace directories are discovered automatically.

```yaml
---
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - ./externalsecret.yaml
  - ./helmrelease.yaml
```

### 5. Commit and push

```bash
git add kubernetes/apps/<namespace>/<app>
git commit -m "feat(<app>): add <app>"
git push
```

Open a pull request: CI builds every Kustomization with flux-local, renders the Helm diff and posts a risk assessment. Flux picks the change up when it lands on `main` (`task kubernetes:reconcile` to hurry it along).

## Choosing a gateway

Which gateway the route uses is a security decision:

| Gateway | Reachable from | Auth in front |
|---|---|---|
| `envoy-internal` (default) | LAN / VPN only | Authelia (two-factor for `admin`, see `kubernetes/apps/default/authelia/app/resources/configuration.yaml`) |
| `envoy-external` | The internet, through the Cloudflare tunnel | None: the app must have its own login |

Only put an app on `envoy-external` if it authenticates users itself (OIDC through Authelia, or its own accounts), and give it a NetworkPolicy that admits only that gateway and a CiliumNetworkPolicy that admits the `kube-apiserver` entity (copy both from `kubernetes/apps/default/radicale/app/helmrelease.yaml`). Apps whose own login should replace the Authelia prompt on the internal gateway go in the `bypass` list in the Authelia configuration.

## Managing Apps

### Force Reconcile

```bash
task kubernetes:reconcile
```

### Check Status

```bash
flux get hr -n <namespace> <app>
flux get ks -n <namespace> <app>
kubectl get pods -n <namespace> -l app.kubernetes.io/name=<app>
```

### Suspend/Resume

```bash
flux suspend ks -n <namespace> <app>
flux suspend hr -n <namespace> <app>

flux resume ks -n <namespace> <app>
flux resume hr -n <namespace> <app>
```

## Renovate

Renovate automerges minor, patch and digest updates once the risk assessment passes and, where the registry gives a release date, once they are 2 days old; majors, `0.x` minors, core infrastructure and apps with database migrations get a pull request to review. See [upgrade procedures](upgrade-procedures.md).
