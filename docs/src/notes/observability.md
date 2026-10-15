# Observability

## In-Cluster Monitoring

### Metrics

Metrics are collected and stored by Prometheus from [kube-prometheus-stack](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack), using the standard CRDs (ServiceMonitor, PodMonitor, PrometheusRule, ScrapeConfig). Retention is 14 days on a 50Gi Ceph volume. Grafana (via the Grafana operator) and kromgo read from `prometheus-operated.observability.svc.cluster.local:9090`.

### Logging

For log collection I use [FluentBit](https://fluentbit.io/). I used to use vector/promtail but gave fluentbit a try and prefer it over the others. It uses minimal resources (~10 mCPU / 15MB RAM) and is fairly easy to configure for label normalization/cleaning.

For log storage I use [Victoria Logs](https://docs.victoriametrics.com/victorialogs/). I switched from Loki and much prefer VM Logs over Loki+Grafana for querying.

Why I switched from Loki:

1. Loki is just a storage layer with no UI - you need Grafana to visualize logs
2. Using Grafana to ad-hoc query logs is tedious and slow
3. Loki is not straightforward to setup
4. VM Logs has a built-in Prometheus-like query dashboard so ad-hoc log diving is simple

### Alerting

Prometheus rules go to [AlertManager](https://prometheus.io/docs/alerting/latest/alertmanager/) from kube-prometheus-stack. Log-based alerts are `VMRule` objects (`vmrule.yaml` next to the apps that have them) evaluated by a `VMAlert` against VictoriaLogs and sent to the same AlertManager; those two kinds need the VictoriaMetrics operator's CRDs, so they only work once it is installed.

For push notifications I paid $5 for [PushOver](https://pushover.net/) and it works great.

## Off-Cluster Monitoring

For things not in this repo, I use a few external services.

### UDM Pro Dynamic DNS

I use Dynamic DNS on my UDM Pro to automatically update an A Record in Cloudflare with my home public IP.

### Healthchecks.io

I have 2 push monitors on [HealthChecks.io](https://healthchecks.io/) to track cluster status externally. They have free push monitors which is why I use it.

1. AlertManager `Watchdog` pings healthchecks.io every 5 minutes - this ensures my alerting is working
2. Gatus endpoint for my [status page](https://status.chestr.dev) - ensures the status page is available

### UptimeRobot

I use [UptimeRobot](https://uptimerobot.com/) to periodically ping the DNS A record set by my UDM to monitor that my home network is reachable externally. Free for 5 minute pings.
