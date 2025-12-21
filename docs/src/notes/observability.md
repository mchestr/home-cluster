# Observability

## In-Cluster Monitoring

### Metrics

I use all the standard Prometheus CRDs for metric collection - ServiceMonitor, PodMonitor, PrometheusRules, etc.

For metrics storage I use [Victoria Metrics](https://victoriametrics.com/). VM is a drop-in replacement for Prometheus which claims to be more performant. For the most part it seems to work well.

Why I switched from Prometheus:

1. Works with all the same CRDs, so I could swap back later if needed
2. Claims to be more performant
3. UI is a bit nicer in my opinion

### Logging

For log collection I use [FluentBit](https://fluentbit.io/). I used to use vector/promtail but gave fluentbit a try and prefer it over the others. It uses minimal resources (~10 mCPU / 15MB RAM) and is fairly easy to configure for label normalization/cleaning.

For log storage I use [Victoria Logs](https://docs.victoriametrics.com/victorialogs/). I switched from Loki and much prefer VM Logs over Loki+Grafana for querying.

Why I switched from Loki:

1. Loki is just a storage layer with no UI - you need Grafana to visualize logs
2. Using Grafana to ad-hoc query logs is tedious and slow
3. Loki is not straightforward to setup
4. VM Logs has a built-in Prometheus-like query dashboard so ad-hoc log diving is simple

### Alerting

For alerting I use [AlertManager](https://prometheus.io/docs/alerting/latest/alertmanager/) via Victoria Metrics.

I run 2 instances of [VMAlert](https://docs.victoriametrics.com/operator/resources/vmalert/) - one for Victoria Metrics rules and one for Victoria Logs rules. Two instances are needed because the query languages are different and would fail if run against the wrong backend.

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
