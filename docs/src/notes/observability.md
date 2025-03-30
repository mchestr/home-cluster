## Observability

### In-Cluster Monitoring

#### Metrics

I use all the standard Prometheus CRDs for metric collection, such as ServiceMonitor/PodMonitor/PrometheusRules etc.

For metrics storage I use [Victoria Metrics](https://victoriametrics.com/).
VM is a drop-in replacement for Prometheus which claims to be more performant than Prometheus.
For the most part it seems to work well.

Reasons for switching from Prometheus:

1. Works with all the same CRDs as Prometheus, so I could swap back later.
2. Claims to be more performant.
3. UI is a bit nicer in my opinion.

#### Logging

To gather logs, I use [FluentBit](https://fluentbit.io/). I used to use vector/promtail however I gave fluentbit
a try and so far I prefer it over the others. Fluent bit uses minimal resources (10 mCPU / 15MB RAM)
and is fairly easy to configure for label normalization/cleaning.

For log storage I use [Victoria Logs](https://docs.victoriametrics.com/victorialogs/).
I switched to VM Logs from Loki and much prefer VM Logs over Loki+Grafana for querying.

Reasons for switching from Loki:

1. Loki is just a storage layer and has no UI, to visualize logs you need to use Grafana.
2. Using Grafana to ad-hoc query logs is tedious and slow
3. Loki is not as straight forward to setup.
4. VM Logs has a built-in Prometheus-like query dashboard so ad-hoc log diving is simple.

#### Alerting

Alerting I use the standard [AlertManager](https://prometheus.io/docs/alerting/latest/alertmanager/) from Prometheus via Victoria Metrics.

I run 2 instance of [VMAlert](https://docs.victoriametrics.com/operator/resources/vmalert/) at the moment, one setup to Alert off Victoria Metric rules, and one to alert off Victoria Log rules. VMAlert will manage pushing alerts to AlertManager.
Right now 2 instances are needed otherwise the query language used in Victoria Log rules will fail if run against Victora Metrics.

For push notifications I paid $5 and use [PushOver](https://pushover.net/).

### Off-Cluster Monitoring

For things not codified in this repo, the following extra external services are used.

#### UDM Pro Dynamic DNS

I use Dynamic DNS on my UDM Pro to automatically update a A Record in Cloudflare that contains my home public IP.

#### Healthchecks.io

I have 2 push monitors setup on [HealthChecks.io](https://healthchecks.io/) to track cluster status externally. Healthchecks has free push monitors which is why I use it.

1. Alertmanager `Watchdog` will ping the healthchecks.io endpoint every 5 minutes.
  a. This ensures my alerting is working correctly.
2. Gatus endpoint for my [status page](https://status.chestr.dev).
  a. This ensures my status page is available and working.

#### UptimeRobot

I use [UptimeRobot](https://uptimerobot.com/) to periodically ping the DNS A record set by my UDM to monitor my home network is reachable externally.
Uptime robot is free for 5 minute pings.
