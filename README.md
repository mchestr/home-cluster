<div align="center">

<img width="144px" height="144px" src="https://raw.githubusercontent.com/mchestr/home-cluster/main/docs/src/assets/logo.png"/>

## My Home Kubernetes Cluster <img src="https://fonts.gstatic.com/s/e/notoemoji/latest/2604_fe0f/512.gif" alt="☄" width="32" height="32">

... managed with Flux and Renovate <img src="https://fonts.gstatic.com/s/e/notoemoji/latest/1f916/512.gif" alt="🤖" width="16" height="16">

</div>

<div align="center">

[![Talos](https://img.shields.io/endpoint?url=https%3A%2F%2Fkromgo.chestr.dev%2Ftalos_version&style=for-the-badge&logo=talos&logoColor=white&color=blue)](https://talos.dev  "Talos OS")&nbsp;&nbsp;
[![Kubernetes](https://img.shields.io/endpoint?url=https%3A%2F%2Fkromgo.chestr.dev%2Fkubernetes_version&style=for-the-badge&logo=kubernetes&logoColor=white&color=blue&label=k8s)](https://kubernetes.io)&nbsp;&nbsp;
[![Flux](https://img.shields.io/endpoint?url=https%3A%2F%2Fkromgo.chestr.dev%2Fflux_version&style=for-the-badge&logo=flux&logoColor=white&color=blue&label=Flux)](https://fluxcd.io)&nbsp;&nbsp;

</div>


<div align="center">

![Home Internet](https://img.shields.io/uptimerobot/status/m798880352-36f58d31f3a556ce80abd5ce?style=for-the-badge&logo=ubiquiti&logoColor=white&label=Home%20Internet)&nbsp;&nbsp;
[![Status Page](https://img.shields.io/endpoint?url=https%3A%2F%2Fhealthchecks.io%2Fbadge%2F47d5c08e-21a9-41f1-b7fd-48092e%2FpXy582uA-2.shields&style=for-the-badge&logo=statuspage&logoColor=white&label=Status%20Page)](https://status.chestr.dev)&nbsp;&nbsp;
[![Alertmanager](https://img.shields.io/endpoint?url=https%3A%2F%2Fhealthchecks.io%2Fbadge%2F47d5c08e-21a9-41f1-b7fd-48092e%2FpXy582uA-2.shields&style=for-the-badge&logo=prometheus&logoColor=white&label=Alertmanager)](https://status.chestr.dev)

</div>

<div align="center">

[![Age-Days](https://img.shields.io/endpoint?url=https%3A%2F%2Fkromgo.chestr.dev%2Fquery%3Fformat%3Dendpoint%26metric%3Dcluster_age_days&style=flat-square&label=Age)](https://github.com/kashalls/kromgo/)&nbsp;
[![Uptime-Days](https://img.shields.io/endpoint?url=https%3A%2F%2Fkromgo.chestr.dev%2Fquery%3Fformat%3Dendpoint%26metric%3Dcluster_uptime_days&style=flat-square&label=Uptime)](https://github.com/kashalls/kromgo/)&nbsp;
[![Node-Count](https://img.shields.io/endpoint?url=https%3A%2F%2Fkromgo.chestr.dev%2Fquery%3Fformat%3Dendpoint%26metric%3Dcluster_node_count&style=flat-square&label=Nodes)](https://github.com/kashalls/kromgo/)&nbsp;
[![Pod-Count](https://img.shields.io/endpoint?url=https%3A%2F%2Fkromgo.chestr.dev%2Fquery%3Fformat%3Dendpoint%26metric%3Dcluster_pod_count&style=flat-square&label=Pods)](https://github.com/kashalls/kromgo/)&nbsp;
[![CPU-Usage](https://img.shields.io/endpoint?url=https%3A%2F%2Fkromgo.chestr.dev%2Fquery%3Fformat%3Dendpoint%26metric%3Dcluster_cpu_usage&style=flat-square&label=CPU)](https://github.com/kashalls/kromgo/)&nbsp;
[![Memory-Usage](https://img.shields.io/endpoint?url=https%3A%2F%2Fkromgo.chestr.dev%2Fquery%3Fformat%3Dendpoint%26metric%3Dcluster_memory_usage&style=flat-square&label=Memory)](https://github.com/kashalls/kromgo/)&nbsp;
[![Power-Usage](https://img.shields.io/endpoint?url=https%3A%2F%2Fkromgo.chestr.dev%2Fquery%3Fformat%3Dendpoint%26metric%3Dcluster_power_usage&style=flat-square&label=Power)](https://github.com/kashalls/kromgo/)&nbsp;
[![Alerts](https://img.shields.io/endpoint?url=https%3A%2F%2Fkromgo.chestr.dev%2Fcluster_alert_count&style=flat-square&label=Alerts)](https://github.com/kashalls/kromgo)

</div>

</div>

## Overview

This repository is my home Kubernetes cluster in a declarative state. [Flux](https://github.com/fluxcd/flux2) watches the [kubernetes](./kubernetes/) folder and will make the changes to the cluster based on the YAML manifests.

### <img src="https://fonts.gstatic.com/s/e/notoemoji/latest/1f4a1/512.gif" alt="💡" width="16" height="16"> Core Components

Core components that form the foundation of the cluster:

- [backube/volsync](https://github.com/backube/volsync) and [backube/snapscheduler](https://github.com/backube/snapscheduler): Backup and recovery of persistent volume claims.
- [cilium/cilium](https://github.com/cilium/cilium): Kubernetes CNI.
- [envoyproxy/envoy](https://github.com/envoyproxy/gateway): Kubernetes-based application gateway using [Kubernetes Gateway API](https://gateway-api.sigs.k8s.io/).
- [external-secrets/external-secrets](https://github.com/external-secrets/external-secrets): Managed Kubernetes secrets using [1Password Connect](https://github.com/1Password/connect).
- [jetstack/cert-manager](https://cert-manager.io/docs/): Creates SSL certificates for services in my Kubernetes cluster.
- [kubernetes-sigs/external-dns](https://github.com/kubernetes-sigs/external-dns): Automatically manages DNS records from my cluster in CloudFlare.
- [rancher/system-upgrade-controller](https://github.com/rancher/system-upgrade-controller): Handles Kubernetes and Talos upgrades automatically.
- [rook/rook](https://github.com/rook/rook): Distributed block storage for peristent storage.
- [siderolabs/talos](https://www.talos.dev/): The Kubernetes Operating System.

### <img src="https://fonts.gstatic.com/s/e/notoemoji/latest/1f6a8/512.gif" alt="🚨" width="16" height="16"> Observability

For observability and monitoring of the cluster the following software is used:

- [fluent/fluent-bit](https://github.com/fluent/fluent-bit): Log processor.
- [grafana/grafana](https://github.com/grafana/grafana): Data visualization platform.
- [prometheus/alertmanager](https://github.com/prometheus/alertmanager): Handles processing and sending alerts.
- [pushover](https://pushover.net): Handles receiving alerts on my devices.
- [TwiN/gatus](https://github.com/TwiN/gatus): High level status dashboard.
- [VictoriaMetrics/VictoriaLogs](https://docs.victoriametrics.com/victorialogs/): Database for logs.
- [VictoriaMetrics/VictoriaMetrics](https://github.com/VictoriaMetrics/VictoriaMetrics): Time series database, drop-in replacement for Prometheus.

### <img src="https://fonts.gstatic.com/s/e/notoemoji/latest/1f916/512.gif" alt="🤖" width="16" height="16"> Automation

- [Github Actions](https://docs.github.com/en/actions) for checking code formatting and running periodic jobs
- [Renovate](https://github.com/renovatebot/renovate) keeps the application charts and container images up-to-date

### <img src="https://fonts.gstatic.com/s/e/notoemoji/latest/1f32a_fe0f/512.gif" alt="🌪" width="16" height="16"> Cloud Dependencies

- [1Password](https://1password.com) for managing secrets via external-secrets.
- [AWS SES](https://aws.amazon.com/ses/) for sending emails.
- [Cloudflare](https://cloudflare.com) tunnels for exposing services & creating certificates & managing domains.
- [Cloudflare R2](https://www.cloudflare.com/developer-platform/r2/) for daily backups.
- [Pushover](https://pushover.net/) for sending alerts.

Total cloud costs yearly is approximately ~$150/year.

### <img src="https://fonts.gstatic.com/s/e/notoemoji/latest/1f35d/512.gif" alt="🍝" width="16" height="16"> Directories

This Git repository contains the following directories.

```sh
📁 bootstrap       # Flux installation to bootstrap cluster
📁 docs            # Docs
📁 hacks           # Contains random scripts
📁 kubernetes      # Kubernetes cluster defined as code
├─📁 flux          # Main Flux configuration of repository
├─📁 components    # Flux components
└─📁 apps          # Apps deployed into my cluster grouped by namespace
📁 talos           # Contains the configuration for Talos operating system
📁 terraform       # Contains Cloudflare terraform
```


## <img src="https://fonts.gstatic.com/s/e/notoemoji/latest/2699_fe0f/512.gif" alt="⚙" width="16" height="16"> Hardware

<details>
  <summary>Checkout my rack</summary>

  <img src="https://raw.githubusercontent.com/mchestr/home-cluster/main/docs/src/assets/myrack.jpg" align="center" alt="rack" height="900px"/>
</details>


| Device                                                | Count | OS Disk Size  | Data Disk Size       | Ram     | Operating System | Purpose           |
|-------------------------------------------------------|-------|---------------|----------------------|---------|------------------|-------------------|
| UDM-Pro-Max                                           | 1     | -             | -                    | -       | Unifi             | Router            |
| USW-Pro-Aggregation                                   | 1     | -             | -                    | -       | Unifi             | Switch            |
| USW-Pro-Max-24-PoE                                    | 1     | -             | -                    | -       | Unifi             | Switch            |
| UAP-AC-Lite                                           | 1     | -             | -                    | -       | Unifi             | WiFi AP           |
| ER-10X                                                | 1     | -             | -                    | -       | EdgeOS           | Switch            |
| PiKVM V4 Mini                                         | 1     | -             | -                    | -       | PiKVM            | KVM               |
| TESmart HDMI KVM Switch 8 Ports                       | 1     | -             | -                    | -       | -                | KVM Switch        |
| CyberPower CP1500PFCRM2U                              | 1     | -             | -                    |         | -                | UPS               |
| USP-PDU-Pro                                           | 1     | -             | -                    | -       | Unifi             | PDU               |
| Synology DS920+                                       | 1     | -             | 2x8TB & 2x16TB       | 20GB    | DSM              | NAS               |
| MS-01 i9-13900H                                       | 3     | 1TB           | 2TB                  | 96GB    | Talos            | Control Plane     |

---

## <img src="https://fonts.gstatic.com/s/e/notoemoji/latest/1f64f/512.gif" alt="🙏" width="16" height="16"> Graditude and Thanks

Thanks to all the people who donate their time to the [Kubernetes @Home](https://github.com/k8s-at-home/) community.

This repository was built off the [onedr0p/template-cluster-k3s](https://github.com/onedr0p/flux-cluster-template) repository.

## <img src="https://fonts.gstatic.com/s/e/notoemoji/latest/2728/512.gif" alt="✨" width="16" height="16"> Star History

[![Star History Chart](https://api.star-history.com/svg?repos=mchestr/home-cluster&type=Date)](https://star-history.com/#mchestr/home-cluster&Date)

## <img src="https://fonts.gstatic.com/s/e/notoemoji/latest/270f_fe0f/512.gif" alt="✏" width="16" height="16"> License

See [LICENSE](./LICENSE)
