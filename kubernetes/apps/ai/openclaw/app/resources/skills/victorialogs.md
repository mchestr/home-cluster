---
name: victorialogs
description: Query cluster application logs during investigations. This cluster stores logs in VictoriaLogs, exposed through the VictoriaLogs HTTP API.
metadata:
  { "openclaw": { "emoji": "logs", "homepage": "https://docs.victoriametrics.com/victorialogs/querying/" } }
user-invocable: true
disable-model-invocation: false
---

Use this skill whenever you need Kubernetes container logs during an
investigation, especially after a Prometheus alert points at a namespace,
pod, app, node, or workload.

Logs are collected by Fluent Bit and stored in VictoriaLogs. Use the
VictoriaLogs LogsQL HTTP API below.

## Endpoint

Base URL (in-cluster, no auth): `http://victoria-logs-server.observability.svc.cluster.local:9428`

Query it with `curl` from the exec tool. Always send LogsQL in the `query`
form field and keep result sets bounded with `_time` filters and `limit`.
Pipe JSON lines through `jq` if available.

## Common API calls

Recent logs for an app:

```sh
curl -s http://victoria-logs-server.observability.svc.cluster.local:9428/select/logsql/query \
  -d 'query=app:"openclaw" AND _time:30m | fields _time, k_namespace_name, k_pod_name, app, _msg | limit 100'
```

Recent logs for a namespace:

```sh
curl -s http://victoria-logs-server.observability.svc.cluster.local:9428/select/logsql/query \
  -d 'query=k_namespace_name:"rook-ceph" AND _time:30m | fields _time, k_pod_name, app, _msg | limit 100'
```

Recent logs for a pod:

```sh
curl -s http://victoria-logs-server.observability.svc.cluster.local:9428/select/logsql/query \
  -d 'query=k_pod_name:"<pod-name>" AND _time:30m | fields _time, app, _msg | limit 100'
```

Error-like logs near an alert:

```sh
curl -s http://victoria-logs-server.observability.svc.cluster.local:9428/select/logsql/query \
  -d 'query=(error OR failed OR panic OR timeout OR denied OR refused OR OOMKilled) AND _time:30m | fields _time, k_namespace_name, k_pod_name, app, _msg | limit 200'
```

Discover useful fields:

```sh
curl -s http://victoria-logs-server.observability.svc.cluster.local:9428/select/logsql/field_names \
  -d 'query=_time:30m'
```

Discover streams matching a symptom:

```sh
curl -s http://victoria-logs-server.observability.svc.cluster.local:9428/select/logsql/streams \
  -d 'query=error AND _time:30m' \
  -d 'limit=20'
```

## Cluster log fields

Fluent Bit normalizes Kubernetes metadata into these useful fields:

- `k_namespace_name`: Kubernetes namespace.
- `k_pod_name`: Kubernetes pod name.
- `app`: best-effort app/container label.
- `_time`: log timestamp.
- `_msg`: log message.
- `source`: always `home-cluster`.

## Investigation flow

- Start from alert labels and query narrowly by namespace, pod, or app.
- Look at logs around `startsAt` first; widen to 30m or 1h only if needed.
- Prefer specific terms from the alert summary before broad error searches.
- Cross-check log evidence with Kubernetes events, pod status, and
  Prometheus metrics before naming a root cause.
- Stay read-only during alert investigations.
