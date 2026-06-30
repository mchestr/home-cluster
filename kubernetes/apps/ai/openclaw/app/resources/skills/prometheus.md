---
name: prometheus
description: Query the cluster Prometheus HTTP API (PromQL) to inspect metrics, alerts, and targets during investigations
metadata:
  { "openclaw": { "emoji": "📊", "homepage": "https://prometheus.io/docs/prometheus/latest/querying/api/" } }
user-invocable: true
disable-model-invocation: false
---

Use this skill whenever you need live or historical metrics from the cluster
Prometheus — triaging an alert, confirming a symptom, or checking trends.

## Endpoint

Base URL (in-cluster, no auth): `http://prometheus-operated.observability.svc.cluster.local:9090`

Query it with `curl` from the exec tool. Always URL-encode the query
(`curl --data-urlencode`). Pipe through `jq` if available.

## Common API calls

Instant query (current value):

```sh
curl -sG http://prometheus-operated.observability.svc.cluster.local:9090/api/v1/query \
  --data-urlencode 'query=up == 0'
```

Range query (trend over a window; start/end are Unix timestamps in seconds —
compute them with `date +%s`):

```sh
curl -sG http://prometheus-operated.observability.svc.cluster.local:9090/api/v1/query_range \
  --data-urlencode 'query=rate(container_cpu_usage_seconds_total[5m])' \
  --data-urlencode 'start=<unix-ts-1h-ago>' \
  --data-urlencode 'end=<unix-ts-now>' \
  --data-urlencode 'step=60'
```

Currently firing alerts: `GET /api/v1/alerts`
Scrape targets / health:   `GET /api/v1/targets`
List metric names:         `GET /api/v1/label/__name__/values`

## Useful PromQL for triage

- Pods restarting:        `increase(kube_pod_container_status_restarts_total[15m]) > 0`
- Pods not running:       `kube_pod_status_phase{phase!="Running",phase!="Succeeded"} == 1`
- OOMKilled containers:   `kube_pod_container_status_last_terminated_reason{reason="OOMKilled"}`
- Container memory vs limit: `container_memory_working_set_bytes / kube_pod_container_resource_limits{resource="memory"}`
- Node memory pressure:   `(1 - node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes) * 100`
- Node disk usage:        `(1 - node_filesystem_avail_bytes{fstype!~"tmpfs|overlay"} / node_filesystem_size_bytes) * 100`
- PVC nearly full:        `kubelet_volume_stats_used_bytes / kubelet_volume_stats_capacity_bytes > 0.85`
- Down scrape targets:    `up == 0`
- Ceph health:            `ceph_health_status`
- Per-pod CPU (cores):    `sum by (pod) (rate(container_cpu_usage_seconds_total{container!=""}[5m]))`

## Tips

- Scope queries with label matchers (e.g. `{namespace="rook-ceph"}`) to cut noise.
- Use `topk(10, ...)` to surface the worst offenders.
- Cross-check a metric spike against Kubernetes MCP pod events and logs before
  concluding a root cause.
- For Alertmanager-triggered investigations, start with the alert's labels
  (`namespace`, `pod`, `node`, `job`, `instance`) and compare the firing time
  against recent Prometheus metrics. Use the victorialogs skill when
  container logs are needed to confirm the failure mode.
