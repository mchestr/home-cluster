<div align="center">

<img width="144px" height="144px" src="https://raw.githubusercontent.com/mchestr/home-cluster/main/docs/src/assets/logo.png"/>

## My Home Kubernetes Cluster <img src="https://fonts.gstatic.com/s/e/notoemoji/latest/2604_fe0f/512.gif" alt="☄" width="32" height="32">

... managed with Flux and Renovate <img src="https://fonts.gstatic.com/s/e/notoemoji/latest/1f916/512.gif" alt="🤖" width="16" height="16">

</div>

<div align="center">

<div>

[![Talos](https://img.shields.io/endpoint?url=https%3A%2F%2Fkromgo.chestr.dev%2Ftalos_version&style=for-the-badge&logo=talos&logoColor=white&color=blue)](https://talos.dev  "Talos OS")&nbsp;&nbsp;
[![Kubernetes](https://img.shields.io/endpoint?url=https%3A%2F%2Fkromgo.chestr.dev%2Fkubernetes_version&style=for-the-badge&logo=kubernetes&logoColor=white&color=blue&label=k8s)](https://kubernetes.io)&nbsp;&nbsp;
[![Flux](https://img.shields.io/endpoint?url=https%3A%2F%2Fkromgo.chestr.dev%2Fflux_version&style=for-the-badge&logo=flux&logoColor=white&color=blue&label=Flux)](https://fluxcd.io)&nbsp;&nbsp;

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

- [backube/volsync](https://github.com/backube/volsync) and [backube/snapscheduler](https://github.com/backube/snapscheduler): Backup and recovery of persistent volume claims.
- [cilium/cilium](https://github.com/cilium/cilium): Kubernetes CNI.
- [external-secrets/external-secrets](https://github.com/external-secrets/external-secrets): Managed Kubernetes secrets using [1Password Connect](https://github.com/1Password/connect).
- [jetstack/cert-manager](https://cert-manager.io/docs/): Creates SSL certificates for services in my Kubernetes cluster.
- [kubernetes-sigs/external-dns](https://github.com/kubernetes-sigs/external-dns): Automatically manages DNS records from my cluster in CloudFlare.
- [kubernetes/ingress-nginx](https://github.com/kubernetes/ingress-nginx/): Ingress controller to expose HTTP traffic to pods over DNS.
- [mozilla/sops](https://toolkit.fluxcd.io/guides/mozilla-sops/): Manages secrets for Kubernetes, Ansible and Terraform which are committed to git.
- [rancher/system-upgrade-controller](https://github.com/rancher/system-upgrade-controller): Handles Kubernetes and Talos upgrades automatically.
- [rook/rook](https://github.com/rook/rook): Distributed block storage for peristent storage.
- [siderolabs/talos](https://www.talos.dev/): The Kubernetes Operating System.

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
📁 ansible         # Ansible playbooks my router
📁 hacks           # Contains random scripts
📁 kubernetes      # Kubernetes cluster defined as code
├─📁 bootstrap     # Flux installation to bootstrap cluster
├─📁 flux           # Main Flux configuration of repository
└─📁 apps          # Apps deployed into my cluster grouped by namespace
📁 talos           # Contains the configuration for Talos operating system
📁 terraform       # Contains Cloudflare terraform
```

## <img src="https://fonts.gstatic.com/s/e/notoemoji/latest/2699_fe0f/512.gif" alt="⚙" width="16" height="16"> Hardware

My mish-mash setup of random hardware I managed to acquire. I also have a few SBC RaspberryPi/ODROIDs lying around, but haven't had a lot of good luck running k3s on them, so sticking to amd64 based machines for now.

| Device                                                | Count | OS Disk Size  | Data Disk Size       | Ram     | Operating System | Purpose           |
|-------------------------------------------------------|-------|---------------|----------------------|---------|------------------|-------------------|
| HP EliteDesk 800 G1                                   | 1     | 512GB SSD     | 512GB                | 8GB     | Talos            | control-plane     |
| HP EliteDesk 800 G3                                   | 2     | 256/512GB SSD | 512GB                | 16GB    | Talos            | control-plane     |
| HP EliteDesk 800 G4                                   | 2     | 256 SSD       | 256GB                | 16/32GB | Talos            | worker            |
| i5-2500K/R7 370 (old repurposed gaming computer)      | 1     | 120GB SSD     | N/A                  | 24GB    | Talos            | worker            |
| i5-6700K/GTX1080 (repurposed gaming computer)         | 1     | 256GB SSD     | N/A                  | 32GB    | Talos            | worker            |
| Synology DS920+                                       | 1     | N/A           | 2x8TB & 2x4TB        | 20GB    | DSM              | NAS               |
| CyberPower CP1500AVRLCD                               | 1     | N/A           | N/A                  | N/A     | N/A              | UPS               |
| Ubiquiti EdgeRouter 10X                               | 1     | N/A           | N/A                  | 512MB   | EdgeOS           | Router            |
| Ubiquiti UAP-AC-Lite                                  | 1     | N/A           | N/A                  | N/A     | N/A              | WiFi AP           |
| PiKVM V4 Mini                                         | 1     | N/A           | N/A                  | N/A     | PiKVM            | KVM               |
| TESmart HDMI KVM Switch 8 Ports                       | 1     | N/A           | N/A                  | N/A     | N/A              | KVM Switch        |
| TP-Link TL-SG1024D 24 Port 1Gbps Switch               | 1     | N/A           | N/A                  | N/A     | N/A              | Network Switch    |

---

## <img src="https://fonts.gstatic.com/s/e/notoemoji/latest/1f64f/512.gif" alt="🙏" width="16" height="16"> Graditude and Thanks

Thanks to all the people who donate their time to the [Kubernetes @Home](https://github.com/k8s-at-home/) community.

This repository was built off the [onedr0p/template-cluster-k3s](https://github.com/onedr0p/flux-cluster-template) repository.

## <img src="https://fonts.gstatic.com/s/e/notoemoji/latest/2728/512.gif" alt="✨" width="16" height="16"> Star History

[![Star History Chart](https://api.star-history.com/svg?repos=mchestr/home-cluster&type=Date)](https://star-history.com/#mchestr/home-cluster&Date)

## <img src="https://fonts.gstatic.com/s/e/notoemoji/latest/270f_fe0f/512.gif" alt="✏" width="16" height="16"> License

See [LICENSE](./LICENSE)
