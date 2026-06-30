---
name: flux
description: Inspect Flux Kustomization, HelmRelease, source, and reconciliation state in this GitOps-managed cluster
metadata:
  { "openclaw": { "emoji": "flux", "homepage": "https://fluxcd.io/flux/cmd/" } }
user-invocable: true
disable-model-invocation: false
---

Use this skill when an incident may be caused by GitOps drift, failed
reconciliation, a bad HelmRelease, a source problem, or a recently applied
change. This cluster is reconciled by Flux from the `kubernetes/` tree.

Keep investigations read-only unless explicitly told to remediate.

OpenClaw does not have the `flux` or `kubectl` CLI. Use the Kubernetes MCP
tools to inspect Flux custom resources directly.

## Fast checks via Kubernetes MCP

List and read these Flux CRDs across namespaces:

- `kustomizations.kustomize.toolkit.fluxcd.io`
- `helmreleases.helm.toolkit.fluxcd.io`
- `gitrepositories.source.toolkit.fluxcd.io`
- `helmrepositories.source.toolkit.fluxcd.io`
- `ocirepositories.source.toolkit.fluxcd.io`
- `buckets.source.toolkit.fluxcd.io`

For app incidents, read the app namespace's `HelmRelease` and the parent
`Kustomization` that points at the app path. For source/reconcile incidents,
read the relevant source object in `flux-system` or the app namespace.

Inspect these fields:

- `.status.conditions[]` with `type`, `status`, `reason`, `message`, and
  `lastTransitionTime`.
- `.status.lastAttemptedRevision`, `.status.lastAppliedRevision`,
  `.status.lastHandledReconcileAt`, and inventory/snapshot fields when
  present.
- `.spec.dependsOn`, `.spec.path`, `.spec.interval`, `.spec.retryInterval`,
  `.spec.sourceRef`, `.spec.chartRef`, `.spec.valuesFrom`, and remediation
  settings.
- Events for the Flux object via the kubernetes-events skill.

If more detail is needed, use VictoriaLogs for Flux controller logs in the
`flux-system` namespace (`source-controller`, `kustomize-controller`,
`helm-controller`, and `notification-controller`).

## What to look for

- `Ready=False` Kustomizations or HelmReleases.
- Source fetch errors, auth errors, invalid chart references, or bad values.
- Dependency waits, health check failures, and remediation rollbacks.
- Reconciliation times close to the alert `startsAt` time.
- A Flux failure in the same namespace as the failing workload.

## Investigation flow

- Start by listing Flux Kustomizations and HelmReleases through the
  Kubernetes MCP.
- If an app is failing, inspect its namespace's HelmRelease and parent
  Kustomization.
- Compare Flux reconciliation events with Kubernetes events and app logs.
- Report whether the issue is likely an applied config problem, a failed
  reconciliation, or runtime failure after a successful reconcile.
