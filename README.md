<div align="center">

<img width="144px" height="144px" src="https://camo.githubusercontent.com/5b298bf6b0596795602bd771c5bddbb963e83e0f/68747470733a2f2f692e696d6775722e636f6d2f7031527a586a512e706e67"/>

## My home Kubernetes cluster :sailboat:

... managed with Flux and Renovate :robot:

</div>

<div align="center">

<div>

[![Cluster](https://status.chestr.dev/api/badge/11/uptime/24?style=for-the-badge&color=blue)](https://status.chestr.dev "Uptime")

</div>
<div>

[![Discord](https://img.shields.io/discord/673534664354430999?style=for-the-badge&label&logo=discord&logoColor=white&color=blue)](https://discord.gg/k8s-at-home)
[![k8s](https://img.shields.io/badge/k8s-v1.29.0-blue?style=for-the-badge)](https://kubernetes.io/)
[![Talos](https://img.shields.io/badge/Talos-v1.6.1-blue?style=for-the-badge)](https://talos.dev "Talos OS")
[![renovate](https://img.shields.io/badge/renovate-enabled-blue?style=for-the-badge&logo=data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjUgNSAzNzAgMzcwIj48Y2lyY2xlIGN4PSIxODkiIGN5PSIxOTAiIHI9IjE4NCIgZmlsbD0iI2ZlMiIvPjxwYXRoIGZpbGw9IiM4YmIiIGQ9Ik0yNTEgMjU2bC0zOC0zOGExNyAxNyAwIDAxMC0yNGw1Ni01NmMyLTIgMi02IDAtN2wtMjAtMjFhNSA1IDAgMDAtNyAwbC0xMyAxMi05LTggMTMtMTNhMTcgMTcgMCAwMTI0IDBsMjEgMjFjNyA3IDcgMTcgMCAyNGwtNTYgNTdhNSA1IDAgMDAwIDdsMzggMzh6Ii8+PHBhdGggZmlsbD0iI2Q1MSIgZD0iTTMwMCAyODhsLTggOGMtNCA0LTExIDQtMTYgMGwtNDYtNDZjLTUtNS01LTEyIDAtMTZsOC04YzQtNCAxMS00IDE1IDBsNDcgNDdjNCA0IDQgMTEgMCAxNXoiLz48cGF0aCBmaWxsPSIjYjMwIiBkPSJNMjg1IDI1OGw3IDdjNCA0IDQgMTEgMCAxNWwtOCA4Yy00IDQtMTEgNC0xNiAwbC02LTdjNCA1IDExIDUgMTUgMGw4LTdjNC01IDQtMTIgMC0xNnoiLz48cGF0aCBmaWxsPSIjYTMwIiBkPSJNMjkxIDI2NGw4IDhjNCA0IDQgMTEgMCAxNmwtOCA3Yy00IDUtMTEgNS0xNSAwbC05LThjNSA1IDEyIDUgMTYgMGw4LThjNC00IDQtMTEgMC0xNXoiLz48cGF0aCBmaWxsPSIjZTYyIiBkPSJNMjYwIDIzM2wtNC00Yy02LTYtMTctNi0yMyAwLTcgNy03IDE3IDAgMjRsNCA0Yy00LTUtNC0xMSAwLTE2bDgtOGM0LTQgMTEtNCAxNSAweiIvPjxwYXRoIGZpbGw9IiNiNDAiIGQ9Ik0yODQgMzA0Yy00IDAtOC0xLTExLTRsLTQ3LTQ3Yy02LTYtNi0xNiAwLTIybDgtOGM2LTYgMTYtNiAyMiAwbDQ3IDQ2YzYgNyA2IDE3IDAgMjNsLTggOGMtMyAzLTcgNC0xMSA0em0tMzktNzZjLTEgMC0zIDAtNCAybC04IDdjLTIgMy0yIDcgMCA5bDQ3IDQ3YTYgNiAwIDAwOSAwbDctOGMzLTIgMy02IDAtOWwtNDYtNDZjLTItMi0zLTItNS0yeiIvPjxwYXRoIGZpbGw9IiMxY2MiIGQ9Ik0xNTIgMTEzbDE4LTE4IDE4IDE4LTE4IDE4em0xLTM1bDE4LTE4IDE4IDE4LTE4IDE4em0tOTAgODlsMTgtMTggMTggMTgtMTggMTh6bTM1LTM2bDE4LTE4IDE4IDE4LTE4IDE4eiIvPjxwYXRoIGZpbGw9IiMxZGQiIGQ9Ik0xMzQgMTMxbDE4LTE4IDE4IDE4LTE4IDE4em0tMzUgMzZsMTgtMTggMTggMTgtMTggMTh6Ii8+PHBhdGggZmlsbD0iIzJiYiIgZD0iTTExNiAxNDlsMTgtMTggMTggMTgtMTggMTh6bTU0LTU0bDE4LTE4IDE4IDE4LTE4IDE4em0tODkgOTBsMTgtMTggMTggMTgtMTggMTh6bTEzOS04NWwyMyAyM2M0IDQgNCAxMSAwIDE2TDE0MiAyNDBjLTQgNC0xMSA0LTE1IDBsLTI0LTI0Yy00LTQtNC0xMSAwLTE1bDEwMS0xMDFjNS01IDEyLTUgMTYgMHoiLz48cGF0aCBmaWxsPSIjM2VlIiBkPSJNMTM0IDk1bDE4LTE4IDE4IDE4LTE4IDE4em0tNTQgMThsMTgtMTcgMTggMTctMTggMTh6bTU1LTUzbDE4LTE4IDE4IDE4LTE4IDE4em05MyA0OGwtOC04Yy00LTUtMTEtNS0xNiAwTDEwMyAyMDFjLTQgNC00IDExIDAgMTVsOCA4Yy00LTQtNC0xMSAwLTE1bDEwMS0xMDFjNS00IDEyLTQgMTYgMHoiLz48cGF0aCBmaWxsPSIjOWVlIiBkPSJNMjcgMTMxbDE4LTE4IDE4IDE4LTE4IDE4em01NC01M2wxOC0xOCAxOCAxOC0xOCAxOHoiLz48cGF0aCBmaWxsPSIjMGFhIiBkPSJNMjMwIDExMGwxMyAxM2M0IDQgNCAxMSAwIDE2TDE0MiAyNDBjLTQgNC0xMSA0LTE1IDBsLTEzLTEzYzQgNCAxMSA0IDE1IDBsMTAxLTEwMWM1LTUgNS0xMSAwLTE2eiIvPjxwYXRoIGZpbGw9IiMxYWIiIGQ9Ik0xMzQgMjQ4Yy00IDAtOC0yLTExLTVsLTIzLTIzYTE2IDE2IDAgMDEwLTIzTDIwMSA5NmExNiAxNiAwIDAxMjIgMGwyNCAyNGM2IDYgNiAxNiAwIDIyTDE0NiAyNDNjLTMgMy03IDUtMTIgNXptNzgtMTQ3bC00IDItMTAxIDEwMWE2IDYgMCAwMDAgOWwyMyAyM2E2IDYgMCAwMDkgMGwxMDEtMTAxYTYgNiAwIDAwMC05bC0yNC0yMy00LTJ6Ii8+PC9zdmc+)](https://github.com/renovatebot/renovate)

</div>

<div align="center">

[![Age-Days](https://img.shields.io/endpoint?url=https%3A%2F%2Fkromgo.chestr.dev%2Fquery%3Fformat%3Dendpoint%26metric%3Dcluster_age_days&style=flat-square&label=Age)](https://github.com/kashalls/kromgo/)&nbsp;&nbsp;
[![Uptime-Days](https://img.shields.io/endpoint?url=https%3A%2F%2Fkromgo.chestr.dev%2Fquery%3Fformat%3Dendpoint%26metric%3Dcluster_uptime_days&style=flat-square&label=Uptime)](https://github.com/kashalls/kromgo/)&nbsp;&nbsp;
[![Node-Count](https://img.shields.io/endpoint?url=https%3A%2F%2Fkromgo.chestr.dev%2Fquery%3Fformat%3Dendpoint%26metric%3Dcluster_node_count&style=flat-square&label=Nodes)](https://github.com/kashalls/kromgo/)&nbsp;&nbsp;
[![Pod-Count](https://img.shields.io/endpoint?url=https%3A%2F%2Fkromgo.chestr.dev%2Fquery%3Fformat%3Dendpoint%26metric%3Dcluster_pod_count&style=flat-square&label=Pods)](https://github.com/kashalls/kromgo/)&nbsp;&nbsp;
[![CPU-Usage](https://img.shields.io/endpoint?url=https%3A%2F%2Fkromgo.chestr.dev%2Fquery%3Fformat%3Dendpoint%26metric%3Dcluster_cpu_usage&style=flat-square&label=CPU)](https://github.com/kashalls/kromgo/)&nbsp;&nbsp;
[![Memory-Usage](https://img.shields.io/endpoint?url=https%3A%2F%2Fkromgo.chestr.dev%2Fquery%3Fformat%3Dendpoint%26metric%3Dcluster_memory_usage&style=flat-square&label=Memory)](https://github.com/kashalls/kromgo/)&nbsp;&nbsp;
[![Power-Usage](https://img.shields.io/endpoint?url=https%3A%2F%2Fkromgo.chestr.dev%2Fquery%3Fformat%3Dendpoint%26metric%3Dcluster_power_usage&style=flat-square&label=Power)](https://github.com/kashalls/kromgo/)

</div>

</div>

## Overview

This repository is my home Kubernetes cluster in a declarative state. [Flux](https://github.com/fluxcd/flux2) watches the [kubernetes](./kubernetes/) folder and will make the changes to the cluster based on the YAML manifests.

### Core Components

- [backube/volsync](https://github.com/backube/volsync) and [backube/snapscheduler](https://github.com/backube/snapscheduler): Backup and recovery of persistent volume claims.
- [cilium/cilium](https://github.com/cilium/cilium): Kubernetes CNI.
- [jetstack/cert-manager](https://cert-manager.io/docs/): Creates SSL certificates for services in my Kubernetes cluster.
- [kubernetes-sigs/external-dns](https://github.com/kubernetes-sigs/external-dns): Automatically manages DNS records from my cluster in CloudFlare.
- [kubernetes/ingress-nginx](https://github.com/kubernetes/ingress-nginx/): Ingress controller to expose HTTP traffic to pods over DNS.
- [mozilla/sops](https://toolkit.fluxcd.io/guides/mozilla-sops/): Manages secrets for Kubernetes, Ansible and Terraform.
- [rancher/system-upgrade-controller](https://github.com/rancher/system-upgrade-controller): Handles Kubernetes and Talos upgrades automatically.
- [rook/rook](https://github.com/rook/rook): Distributed block storage for peristent storage.
- [siderolabs/talos](https://www.talos.dev/): The Kubernetes Operating System.

### :robot:&nbsp; Automation

- [Github Actions](https://docs.github.com/en/actions) for checking code formatting and running periodic jobs
- [Renovate](https://github.com/renovatebot/renovate) keeps the application charts and container images up-to-date

### :cloud: Cloud Dependencies

- [1Password](https://1password.com) for managing secrets via external-secrets.
- [AWS SES](https://aws.amazon.com/ses/) for sending emails.
- [Cloudflare](https://cloudflare.com) tunnels for exposing services & creating certificates & managing domains.
- [Cloudflare R2](https://www.cloudflare.com/developer-platform/r2/) for daily backups.
- [Google Cloud](https://cloud.google.com) to deploy [uptime-kuma](https://github.com/louislam/uptime-kuma) for external cluster monitoring.
- [Pushover](https://pushover.net/) for sending alerts.

Total cloud costs yearly is approximately ~$150/year.

### Directories

This Git repository contains the following directories.

```sh
📁 ansible         # Ansible playbooks for various systems managed outside the cluster
📁 hacks           # Contains random scripts
📁 kubernetes      # Kubernetes cluster defined as code
├─📁 bootstrap     # Flux installation to bootstrap cluster
├─📁 flux           # Main Flux configuration of repository
└─📁 apps          # Apps deployed into my cluster grouped by namespace
📁 talos           # Contains the configuration for Talos operating system
📁 terraform       # Contains Cloudflare & Google Compute infrastructure applied automatically by Flux tf-controller
```

## 🔧 Hardware

My mash-mash setup of random hardware I managed to acquire. I also have a few SBC RaspberryPi/ODROIDs lying around, but haven't had a lot of good luck running k3s on them, so sticking to amd64 based machines for now.

| Device                                                | Count | OS Disk Size  | Data Disk Size       | Ram     | Operating System | Purpose           |
|-------------------------------------------------------|-------|---------------|----------------------|---------|------------------|-------------------|
| HP EliteDesk 800 G1                                   | 1     | 512GB SSD     | 512GB                | 8GB     | Talos            | control-plane     |
| HP EliteDesk 800 G3                                   | 2     | 256/512GB SSD | 512GB                | 16GB    | Talos            | control-plane     |
| HP EliteDesk 800 G4                                   | 2     | 256 SSD       | 256GB                | 16/32GB | Talos            | worker            |
| i5-2500K/R7 370 (old repurposed gaming computer)      | 1     | 120GB SSD     | N/A                  | 24GB    | Talos            | worker            |
| i5-6700K/GTX1080 (repurposed gaming computer)         | 1     | 256GB SSD     | N/A                  | 32GB    | Talos            | worker            |
| Synology DS920+                                       | 1     | N/A           | 2x8TB & 2x4TB        | 20GB    | DSM 7.1.1        | NAS               |
| CyberPower CP1500AVRLCD                               | 1     | N/A           | N/A                  | N/A     | N/A              | UPS               |
| Ubiquiti EdgeRouter 10X                               | 1     | N/A           | N/A                  | 512MB   | EdgeOS           | Router            |
| Ubiquiti UAP-AC-Lite                                  | 1     | N/A           | N/A                  | N/A     | N/A              | WiFi AP           |
| PiKVM V4 Mini                                         | 1     | N/A           | N/A                  | N/A     | PiKVM            | KVM               |
| TESmart HDMI KVM Switch 8 Ports                       | 1     | N/A           | N/A                  | N/A     | N/A              | KVM Switch        |
| TP-Link TL-SG1024D 24 Port 1Gbps Switch               | 1     | N/A           | N/A                  | N/A     | N/A              | Network Switch    |

---

## 🤝 Graditude and Thanks

Thanks to all the people who donate their time to the [Kubernetes @Home](https://github.com/k8s-at-home/) community.

This repository was built off the [onedr0p/template-cluster-k3s](https://github.com/onedr0p/flux-cluster-template) repository.

## 🔏 License

See [LICENSE](./LICENSE)
