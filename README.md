# Template for deploying k3s backed by Flux

Highly opinionated template for deploying a single [k3s](https://k3s.io) cluster with [Ansible](https://www.ansible.com) and [Terraform](https://www.terraform.io) backed by [Flux](https://toolkit.fluxcd.io/) and [SOPS](https://toolkit.fluxcd.io/guides/mozilla-sops/).

The purpose here is to showcase how you can deploy an entire Kubernetes cluster and show it off to the world using the [GitOps](https://www.weave.works/blog/what-is-gitops-really) tool [Flux](https://toolkit.fluxcd.io/). When completed, your Git repository will be driving the state of your Kubernetes cluster. In addition with the help of the [Ansible](https://github.com/ansible-collections/community.sops), [Terraform](https://github.com/carlpett/terraform-provider-sops) and [Flux](https://toolkit.fluxcd.io/guides/mozilla-sops/) SOPS integrations you'll be able to commit GPG encrypted secrets to your public repo.

## Overview

- [Introduction](https://github.com/k8s-at-home/template-cluster-k3s#wave-introduction)
- [Prerequisites](https://github.com/k8s-at-home/template-cluster-k3s#memo-prerequisites)
- [Repository structure](https://github.com/k8s-at-home/template-cluster-k3s#open_file_folder-repository-structure)
- [Lets go!](https://github.com/k8s-at-home/template-cluster-k3s#rocket-lets-go)
- [Post installation](https://github.com/k8s-at-home/template-cluster-k3s#mega-post-installation)
- [Thanks](https://github.com/k8s-at-home/template-cluster-k3s#handshake-thanks)

## :wave:&nbsp; Introduction

The following components will be installed in your [k3s](https://k3s.io/) cluster by default. They are only included to get a minimum viable cluster up and running. You are free to add / remove components to your liking but anything outside the scope of the below components are not supported by this template.

Feel free to read up on any of these technologies before you get started to be more familiar with them.

- [flannel](https://github.com/flannel-io/flannel) - default CNI provided by k3s
- [local-path-provisioner](https://github.com/rancher/local-path-provisioner) - default storage class provided by k3s
- [flux](https://toolkit.fluxcd.io/) - GitOps tool for deploying manifests from the `cluster` directory
- [metallb](https://metallb.universe.tf/) - bare metal load balancer
- [cert-manager](https://cert-manager.io/) - SSL certificates - with Cloudflare DNS challenge
- [traefik](https://traefik.io) - ingress controller
- [hajimari](https://github.com/toboshii/hajimari) - start page with ingress discovery
- [system-upgrade-controller](https://github.com/rancher/system-upgrade-controller) - upgrade k3s
- [reloader](https://github.com/stakater/Reloader) - restart pod when configmap or secret changes

## :memo:&nbsp; Prerequisites

### :computer:&nbsp; Systems

- Two nodes with a fresh install of [Ubuntu Server 20.04](https://ubuntu.com/download/server). These nodes can be bare metal or VMs.
- A [Cloudflare](https://www.cloudflare.com/) account with a domain, this will be managed by Terraform.
- Some experience in debugging problems and a positive attitude ;)

### :wrench:&nbsp; Tools

:round_pushpin: You should install the below CLI tools on your workstation. Make sure you pull in the latest versions.

| Tool                                                               | Purpose                                                             |
|--------------------------------------------------------------------|---------------------------------------------------------------------|
| [ansible](https://www.ansible.com)                                 | Preparing Ubuntu for Kubernetes and installing k3s                  |
| [direnv](https://github.com/direnv/direnv)                         | Exports env vars based on present working directory                 |
| [flux](https://toolkit.fluxcd.io/)                                 | Operator that manages your k8s cluster based on your Git repository |
| [GnuPG](https://gnupg.org/)                                        | Encrypts and signs your data                                        |
| [go-task](https://github.com/go-task/task)                         | A task runner / simpler Make alternative written in Go              |
| [helm](https://helm.sh/)                                           | Manage Kubernetes applications                                      |
| [kubectl](https://kubernetes.io/docs/tasks/tools/)                 | Allows you to run commands against Kubernetes clusters              |
| [kustomize](https://kustomize.io/)                                 | Template-free way to customize application configuration            |
| [pinentry](https://gnupg.org/related_software/pinentry/index.html) | Allows GnuPG to read passphrases and PIN numbers                    |
| [pre-commit](https://github.com/pre-commit/pre-commit)             | Runs checks pre `git commit`                                        |
| [prettier](https://github.com/prettier/prettier)                   | Prettier is an opinionated code formatter.                          |
| [SOPS](https://github.com/mozilla/sops)                            | Encrypts k8s secrets with GnuPG                                     |
| [terraform](https://www.terraform.io)                              | Prepare a Cloudflare domain to be used with the cluster             |

### :warning:&nbsp; pre-commit

It is advisable to install [pre-commit](https://pre-commit.com/) and the pre-commit hooks that come with this repository.
[sops-pre-commit](https://github.com/k8s-at-home/sops-pre-commit) will check to make sure you are not by accident commiting your secrets un-encrypted.

After pre-commit is installed on your machine run:

```sh
pre-commit install-hooks
```

## :open_file_folder:&nbsp; Repository structure

The Git repository contains the following directories under `cluster` and are ordered below by how Flux will apply them.

- **base** directory is the entrypoint to Flux
- **crds** directory contains custom resource definitions (CRDs) that need to exist globally in your cluster before anything else exists
- **core** directory (depends on **crds**) are important infrastructure applications (grouped by namespace) that should never be pruned by Flux
- **apps** directory (depends on **core**) is where your common applications (grouped by namespace) could be placed, Flux will prune resources here if they are not tracked by Git anymore

```
cluster
├── apps
│   ├── default
│   ├── networking
│   └── system-upgrade
├── base
│   └── flux-system
├── core
│   ├── cert-manager
│   ├── metallb-system
│   ├── namespaces
│   └── system-upgrade
└── crds
    └── cert-manager
```

## :rocket:&nbsp; Lets go!

Very first step will be to create a new repository by clicking the **Use this template** button on this page.

Clone the repo to you local workstation and `cd` into it.

:round_pushpin: **All of the below commands** are run on your **local** workstation, **not** on any of your cluster nodes.

### :closed_lock_with_key:&nbsp; Setting up GnuPG keys

:round_pushpin: Here we will create a personal and a Flux GPG key. Using SOPS with GnuPG allows us to encrypt and decrypt secrets.

1. Create a Personal GPG Key, password protected, and export the fingerprint. It's **strongly encouraged** to back up this key somewhere safe so you don't lose it.

```sh
export GPG_TTY=$(tty)
export PERSONAL_KEY_NAME="First name Last name (location) <email>"

gpg --batch --full-generate-key <<EOF
Key-Type: 1
Key-Length: 4096
Subkey-Type: 1
Subkey-Length: 4096
Expire-Date: 0
Name-Real: ${PERSONAL_KEY_NAME}
EOF

gpg --list-secret-keys "${PERSONAL_KEY_NAME}"
# pub   rsa4096 2021-03-11 [SC]
#       772154FFF783DE317KLCA0EC77149AC618D75581
# uid           [ultimate] k8s@home (Macbook) <k8s-at-home@gmail.com>
# sub   rsa4096 2021-03-11 [E]
```

2. Create a Flux GPG Key and export the fingerprint

```sh
export GPG_TTY=$(tty)
export FLUX_KEY_NAME="Cluster name (Flux) <email>"

gpg --batch --full-generate-key <<EOF
%no-protection
Key-Type: 1
Key-Length: 4096
Subkey-Type: 1
Subkey-Length: 4096
Expire-Date: 0
Name-Real: ${FLUX_KEY_NAME}
EOF

gpg --list-secret-keys "${FLUX_KEY_NAME}"
# pub   rsa4096 2021-03-11 [SC]
#       AB675CE4CC64251G3S9AE1DAA88ARRTY2C009E2D
# uid           [ultimate] Home cluster (Flux) <k8s-at-home@gmail.com>
# sub   rsa4096 2021-03-11 [E]
```

3. You will need the Fingerprints in the configuration section below. For example, in the above steps you will need `772154FFF783DE317KLCA0EC77149AC618D75581` and `AB675CE4CC64251G3S9AE1DAA88ARRTY2C009E2D`

### :cloud:&nbsp; Global Cloudflare API Key

In order to use Terraform and `cert-manager` with the Cloudflare DNS challenge you will need to create a API key.

1. Head over to Cloudflare and create a API key by going [here](https://dash.cloudflare.com/profile/api-tokens).

2. Under the `API Keys` section, create a global API Key.

3. Use the API Key in the configuration section below.

### :page_facing_up:&nbsp; Configuration

:round_pushpin: The `.config.env` file contains necessary configuration files that are needed by Ansible, Terraform and Flux.

1. Copy the `.config.sample.env` to `.config.env` and start filling out all the environment variables. **All are required** and read the comments they will explain further what is required.

2. Once that is done, verify the configuration is correct by running `./configure.sh --verify`

3. If you do not encounter any errors run `./configure.sh` to start having the script wire up the templated files and place them where they need to be.

### :zap:&nbsp; Preparing Ubuntu with Ansible

:round_pushpin: Here we will be install [k3s](https://k3s.io/) with [this](https://galaxy.ansible.com/xanmanning/k3s) wonderful k3s Ansible galaxy role. After completion, Ansible will drop a `kubeconfig` in `/tmp/kubeconfig` for use with interacting with your cluster with `kubectl`. This file should be manually copied to the root of your repository.

1. Ensure you are able to SSH into you nodes from your workstation with using your private ssh key. This is how Ansible is able to connect to your remote nodes.

2. Verify Ansible can view your config by running `task ansible:list`

3. Verify Ansible can ping your nodes by running `task ansible:ping`

4. Finally, run the Ubuntu Prepare playbook by running `task ansible:playbook:ubuntu-prepare`

5. If everything goes as planned you should see Ansible running the Ubuntu Prepare Playbook against your nodes.

### :sailboat:&nbsp; Installing k3s with Ansible

1. Verify Ansible can view your config by running `task ansible:list`

2. Verify Ansible can ping your nodes by running `task ansible:ping`

3. Run the k3s install playbook by running `task ansible:playbook:k3s-install`

4. If everything goes as planned you should see Ansible running the k3s install Playbook against your nodes.

5. Copy the `kubeconfig` file from `/tmp` to your repository.

6. Verify the nodes are online
   
```sh
kubectl --kubeconfig=./kubeconfig get nodes
# NAME           STATUS   ROLES                       AGE     VERSION
# k8s-0          Ready    control-plane,master      4d20h   v1.21.5+k3s1
# k8s-1          Ready    worker                    4d20h   v1.21.5+k3s1
```

### :small_blue_diamond:&nbsp; GitOps with Flux

:round_pushpin: Here we will be installing [flux](https://toolkit.fluxcd.io/) after some quick bootstrap steps.

1. Verify Flux can be installed

```sh
flux --kubeconfig=./kubeconfig check --pre
# ► checking prerequisites
# ✔ kubectl 1.21.5 >=1.18.0-0
# ✔ Kubernetes 1.21.5+k3s1 >=1.16.0-0
# ✔ prerequisites checks passed
```

2. Pre-create the `flux-system` namespace

```sh
kubectl --kubeconfig=./kubeconfig create namespace flux-system --dry-run=client -o yaml | kubectl --kubeconfig=./kubeconfig apply -f -
```

3. Add the Flux GPG key in-order for Flux to decrypt SOPS secrets

```sh
source .config.env
gpg --export-secret-keys --armor "${BOOTSTRAP_FLUX_KEY_FP}" |
kubectl --kubeconfig=./kubeconfig create secret generic sops-gpg \
    --namespace=flux-system \
    --from-file=sops.asc=/dev/stdin
```

:round_pushpin: Variables defined in `./cluster/base/cluster-secrets.sops.yaml` and `./cluster/base/cluster-settings.sops.yaml` will be usable anywhere in your YAML manifests under `./cluster`

4. **Verify** all the above files are **encrypted** with SOPS

5. If you verified all the secrets are encrypted, you can delete the `tmpl` directory now

6.  Push you changes to git

```sh
git add -A
git commit -m "initial commit"
git push
```

7. Install Flux

:round_pushpin: Due to race conditions with the Flux CRDs you will have to run the below command twice. There should be no errors on this second run.

```sh
kubectl --kubeconfig=./kubeconfig apply --kustomize=./cluster/base/flux-system
# namespace/flux-system configured
# customresourcedefinition.apiextensions.k8s.io/alerts.notification.toolkit.fluxcd.io created
# ...
# unable to recognize "./cluster/base/flux-system": no matches for kind "Kustomization" in version "kustomize.toolkit.fluxcd.io/v1beta1"
# unable to recognize "./cluster/base/flux-system": no matches for kind "GitRepository" in version "source.toolkit.fluxcd.io/v1beta1"
# unable to recognize "./cluster/base/flux-system": no matches for kind "HelmRepository" in version "source.toolkit.fluxcd.io/v1beta1"
# unable to recognize "./cluster/base/flux-system": no matches for kind "HelmRepository" in version "source.toolkit.fluxcd.io/v1beta1"
# unable to recognize "./cluster/base/flux-system": no matches for kind "HelmRepository" in version "source.toolkit.fluxcd.io/v1beta1"
# unable to recognize "./cluster/base/flux-system": no matches for kind "HelmRepository" in version "source.toolkit.fluxcd.io/v1beta1"
```

8. Verify Flux components are running in the cluster

```sh
kubectl --kubeconfig=./kubeconfig get pods -n flux-system
# NAME                                       READY   STATUS    RESTARTS   AGE
# helm-controller-5bbd94c75-89sb4            1/1     Running   0          1h
# kustomize-controller-7b67b6b77d-nqc67      1/1     Running   0          1h
# notification-controller-7c46575844-k4bvr   1/1     Running   0          1h
# source-controller-7d6875bcb4-zqw9f         1/1     Running   0          1h
```

:tada: **Congratulations** you have a Kubernetes cluster managed by Flux, your Git repository is driving the state of your cluster.

### :cloud:&nbsp; Configure Cloudflare DNS with Terraform

:round_pushpin: Review the Terraform scripts under `./terraform/cloudflare/` and make sure you understand what it's doing (no really review it). If your domain already has existing DNS records be sure to export those DNS settings before you continue. Ideally you can update the terraform script to manage DNS for all records if you so choose to.

1. Pull in the Terraform deps by running `task terraform:init`

2. Review the changes Terraform will make to your Cloudflare domain by running `task terraform:plan`

3. Finally have Terraform execute the task by running `task terraform:apply`

If Terraform was ran successfully head over to your browser and you _should_ be able to access `https://hajimari.${BOOTSTRAP_CLOUDFLARE_DOMAIN}`

## :mega:&nbsp; Post installation

### direnv

This is a great tool to export environment variables depending on what your present working directory is, head over to their [installation guide](https://direnv.net/docs/installation.html) and don't forget to hook it into your shell!

When this is done you no longer have to use `--kubeconfig=./kubeconfig` in your `kubectl`, `flux` or `helm` commands.

### VSCode SOPS extension

[VSCode SOPS](https://marketplace.visualstudio.com/items?itemName=signageos.signageos-vscode-sops) is a neat little plugin for those using VSCode.
It will automatically decrypt you SOPS secrets when you click on the file in the editor and encrypt them when you save  and exit the file.

### :point_right:&nbsp; Debugging

Manually sync Flux with your Git repository

```sh
flux --kubeconfig=./kubeconfig reconcile source git flux-system
# ► annotating GitRepository flux-system in flux-system namespace
# ✔ GitRepository annotated
# ◎ waiting for GitRepository reconciliation
# ✔ GitRepository reconciliation completed
# ✔ fetched revision main/943e4126e74b273ff603aedab89beb7e36be4998
```

Show the health of you kustomizations

```sh
kubectl --kubeconfig=./kubeconfig get kustomization -A
# NAMESPACE     NAME          READY   STATUS                                                             AGE
# flux-system   apps          True    Applied revision: main/943e4126e74b273ff603aedab89beb7e36be4998    3d19h
# flux-system   core          True    Applied revision: main/943e4126e74b273ff603aedab89beb7e36be4998    4d6h
# flux-system   crds          True    Applied revision: main/943e4126e74b273ff603aedab89beb7e36be4998    4d6h
# flux-system   flux-system   True    Applied revision: main/943e4126e74b273ff603aedab89beb7e36be4998    4d6h
```

Show the health of your main Flux `GitRepository`

```sh
flux --kubeconfig=./kubeconfig get sources git
# NAME           READY	MESSAGE                                                            REVISION                                         SUSPENDED
# flux-system    True 	Fetched revision: main/943e4126e74b273ff603aedab89beb7e36be4998    main/943e4126e74b273ff603aedab89beb7e36be4998    False
```

Show the health of your `HelmRelease`s

```sh
flux --kubeconfig=./kubeconfig get helmrelease -A
# NAMESPACE   	    NAME                  	READY	MESSAGE                         	REVISION	SUSPENDED
# cert-manager	    cert-manager          	True 	Release reconciliation succeeded	v1.5.2  	False
# default        	hajimari                True 	Release reconciliation succeeded	1.1.1   	False
# networking  	    ingress-nginx       	True 	Release reconciliation succeeded	3.30.0  	False
```

Show the health of your `HelmRepository`s

```sh
flux --kubeconfig=./kubeconfig get sources helm -A
# NAMESPACE  	NAME                 READY	MESSAGE                                                   	REVISION                                	SUSPENDED
# flux-system	bitnami-charts       True 	Fetched revision: 0ec3a3335ff991c45735866feb1c0830c4ed85cf	0ec3a3335ff991c45735866feb1c0830c4ed85cf	False
# flux-system	hajimari-charts      True 	Fetched revision: 1b24af9c5a1e3da91618d597f58f46a57c70dc13	1b24af9c5a1e3da91618d597f58f46a57c70dc13	False
# flux-system	ingress-nginx-charts True 	Fetched revision: 45669a3117fc93acc09a00e9fb9b4445e8990722	45669a3117fc93acc09a00e9fb9b4445e8990722	False
# flux-system	jetstack-charts      True 	Fetched revision: 7bad937cc82a012c9ee7d7a472d7bd66b48dc471	7bad937cc82a012c9ee7d7a472d7bd66b48dc471	False
# flux-system	k8s-at-home-charts   True 	Fetched revision: 1b24af9c5a1e3da91618d597f58f46a57c70dc13	1b24af9c5a1e3da91618d597f58f46a57c70dc13	False
```

Flux has a wide range of CLI options available be sure to run `flux --help` to view more!

### :robot:&nbsp; Automation

- [Renovate](https://www.whitesourcesoftware.com/free-developer-tools/renovate) is a very useful tool that when configured will start to create PRs in your Github repository when Docker images, Helm charts or anything else that can be tracked has a newer version. The configuration for renovate is located [here](./.github/renovate.json5).

- [system-upgrade-controller](https://github.com/rancher/system-upgrade-controller) will watch for new k3s releases and upgrade your nodes when new releases are found.

There's also a couple Github workflows included in this repository that will help automate some processes.

- [Flux upgrade schedule](./.github/workflows/flux-schedule.yaml) - workflow to upgrade Flux.
- [Renovate schedule](./.github/workflows/renovate-schedule.yaml) - workflow to annotate `HelmRelease`'s which allows [Renovate](https://www.whitesourcesoftware.com/free-developer-tools/renovate) to track Helm chart versions.

## :grey_question:&nbsp; What's next

The world is your cluster, try installing another application or if you have a NAS and want storage back by that check out the helm charts for [democratic-csi](https://github.com/democratic-csi/democratic-csi), [csi-driver-nfs](https://github.com/kubernetes-csi/csi-driver-nfs) or [nfs-subdir-external-provisioner](https://github.com/kubernetes-sigs/nfs-subdir-external-provisioner).

If you plan on exposing your ingress to the world from your home. Checkout [our rough guide](https://docs.k8s-at-home.com/guides/dyndns/) to run a k8s `CronJob` to update DDNS.

## :handshake:&nbsp; Thanks

Big shout out to all the authors and contributors to the projects that we are using in this repository.
