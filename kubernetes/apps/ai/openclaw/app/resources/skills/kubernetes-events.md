---
name: kubernetes-events
description: Inspect Kubernetes events, pod status, and object descriptions to explain scheduling, probe, image pull, volume, and lifecycle failures
metadata:
  { "openclaw": { "emoji": "events", "homepage": "https://kubernetes.io/docs/reference/kubernetes-api/cluster-resources/event-v1/" } }
user-invocable: true
disable-model-invocation: false
---

Use this skill early in Kubernetes incident investigations. Events often
explain why a symptom started: failed scheduling, image pull errors, probe
failures, volume attachment problems, evictions, and rollout churn.

OpenClaw does not have `kubectl`. Use the Kubernetes MCP tools to list and
read Kubernetes resources directly.

## Fast checks via Kubernetes MCP

Recent events:

- List `events` in the core API group across namespaces when supported.
- Also list `events.events.k8s.io` if the MCP exposes the newer events API.
- Filter the returned objects by `type: Warning`, `metadata.namespace`,
  `involvedObject`, `regarding`, `reason`, `message`, `firstTimestamp`,
  `lastTimestamp`, `eventTime`, and `count`.

Object state for alert targets:

- Read the Pod, Deployment, StatefulSet, DaemonSet, Job, PVC, Service, or
  EndpointSlice named by alert labels.
- Inspect `.status.conditions`, `.status.containerStatuses`,
  `.status.initContainerStatuses`, `.status.phase`, `.status.reason`,
  `.status.message`, `.spec.nodeName`, `.spec.tolerations`, `.spec.affinity`,
  `.spec.volumes`, and owner references.
- For pod lifecycle issues, inspect waiting/terminated reasons, restart
  counts, readiness, image IDs, last termination state, and mounted PVCs.

Namespace scoping:

- Start with the alert's `namespace`, `pod`, `persistentvolumeclaim`,
  `deployment`, `statefulset`, `daemonset`, `job`, or `node` labels.
- If labels are missing, use the alert `instance`, `app`, and annotations to
  infer the likely namespace/object, then verify with MCP reads.

## What to look for

- `FailedScheduling`: node selectors, taints, resource pressure, PVC binding.
- `FailedMount` or `FailedAttachVolume`: storage, Ceph, CSI, stale attachments.
- `BackOff`, `Unhealthy`, `Killing`: probes, crashes, rollout issues.
- `ErrImagePull` or `ImagePullBackOff`: registry, tag, auth, DNS.
- `Evicted`: node pressure, ephemeral storage, memory pressure.
- `NetworkNotReady` or sandbox failures: CNI or node runtime issues.

## Investigation flow

- Start with the namespace and object labels from the alert payload.
- Compare event timestamps with the alert `startsAt` time.
- Use MCP-read object status for conditions and recent event context.
- Cross-check with Prometheus metrics and VictoriaLogs before concluding.
- Stay read-only during alert investigations.
