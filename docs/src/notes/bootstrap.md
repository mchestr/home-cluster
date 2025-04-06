# Cluster Bootstrap

The process should be mostly automated via the `task bootstrap:apps` command. If all goes well
the cluster should come up based on the last available snapshot taken by volsync, which is run daily.

## Priming the Hardware

1. Grab the latest Talos .iso [here](https://www.talos.dev/v1.9/talos-guides/install/bare-metal-platforms/iso/)
2. Plug it in and follow secure boot setup.

### MS-01 SecureBoot Setup

Enabling Secure boot on MS-01 can be difficult if its not something you have done before, heres how to do it.

1. Boot directly to the BIOS
2. Under `Security`->`Secure Boot` change to `custom`.
3. Go down to `Key Management`
4. Set `Factory Key Provision` to `disabled`.
4. Click `Reset To Setup Mode`.
    - IMPORTANT: click `cancel` when it says save without exiting.
5. Save and Reset.
6. Mount Talos image and reboot, click `Enroll secure boot keys: auto`.

If at any point you still see some errors on start about key violations it most likely means the factory default keys were not wiped (step 4 above). Make sure the changes are saved before rebooting.

### Bootstrap Flux

Flux manages the state of the cluster, but cannot do that until it is installed, in order to install Flux into the cluster
a few things need to be manually installed:

1. [Cilium](https://github.com/cilium/cilium). By default Talos will install a basic CNI, so we disable [that in our config](https://github.com/mchestr/home-cluster/blob/main/talos/controlplane.yaml#L135-L136). Kubernetes doesn't work without a CNI.
1. [CoreDNS](https://coredns.io/). CoreDNS is for in-cluster DNS things, By default Talos will install coredns for us, but that makes it hard to upgrade so [it is disabled](https://github.com/mchestr/home-cluster/blob/main/talos/controlplane.yaml#L140-L141) and we manage that with Flux [here](https://github.com/mchestr/home-cluster/tree/main/kubernetes/apps/kube-system/coredns).
1. [cert-manager](https://cert-manager.io/) for certificate things. Bootstrapping this into the cluster makes this easier as everything is based on my domain.
1. [external-secrets](https://external-secrets.io/latest/) and 1Password. All my secrets are stored in 1Password, we need to configure external-secrets to allow pulling these from 1Password into the cluster secrets.
1. [kubelet-csr-approver](https://github.com/postfinance/kubelet-csr-approver). This thing auto approves csrs, makes life easy.
1. [spegel](https://github.com/spegel-org/spegel). This is an in-cluster OCI registry mirror, to save some bandwidth it is installed beforehand.
1. [Flux](https://fluxcd.io/). Flux itself, after this point Flux will manage the state of the cluster via the manifests in this repository.

All of these are installed with a single command [here](https://github.com/mchestr/home-cluster/blob/main/.taskfiles/bootstrap/Taskfile.yaml#L20). This command will install [extra resources](https://github.com/mchestr/home-cluster/blob/main/bootstrap/resources.yaml) to bootstrap 1Password and CloudFlare tunnel, and then all helm resources are installed via [helmfile](https://helmfile.readthedocs.io/en/latest/) through the [helmfile.yaml](https://github.com/mchestr/home-cluster/blob/main/bootstrap/helmfile.yaml) manifest.
