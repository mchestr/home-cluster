# Cluster Bootstrap

The process should be mostly automated via `task bootstrap:apps`. If all goes well the cluster should come up based on the last available Volsync snapshot, which runs daily.

## Priming the Hardware

1. Grab the latest Talos .iso [here](https://www.talos.dev/v1.9/talos-guides/install/bare-metal-platforms/iso/)
2. Plug it in and follow secure boot setup

### MS-01 SecureBoot Setup

Enabling Secure Boot on MS-01 can be difficult if its not something you have done before, heres how to do it:

1. Boot directly to the BIOS
2. Under `Security`->`Secure Boot` change to `custom`
3. Go down to `Key Management`
4. Set `Factory Key Provision` to `disabled`
5. Click `Reset To Setup Mode`
   - IMPORTANT: click `cancel` when it says save without exiting
6. Save and Reset
7. Mount Talos image and reboot, click `Enroll secure boot keys: auto`

If you still see errors on start about key violations it probably means the factory default keys weren't wiped (step 4). Make sure changes are saved before rebooting.

## Bootstrap Flux

Flux manages the state of the cluster, but it can't do that until its installed. A few things need to be manually installed first:

1. [Cilium](https://github.com/cilium/cilium) - By default Talos installs a basic CNI, so I [disable that](https://github.com/mchestr/home-cluster/blob/main/talos/controlplane.yaml#L135-L136). Kubernetes doesn't work without a CNI.
2. [CoreDNS](https://coredns.io/) - Talos installs this by default but that makes it hard to upgrade so I [disable it](https://github.com/mchestr/home-cluster/blob/main/talos/controlplane.yaml#L140-L141) and manage it with [Flux](https://github.com/mchestr/home-cluster/tree/main/kubernetes/apps/kube-system/coredns).
3. [cert-manager](https://cert-manager.io/) - For certificate things. Bootstrapping this early makes life easier since everything is based on my domain.
4. [external-secrets](https://external-secrets.io/latest/) - All my secrets are in 1Password, this pulls them into the cluster.
5. [kubelet-csr-approver](https://github.com/postfinance/kubelet-csr-approver) - Auto approves CSRs, makes life easy.
6. [spegel](https://github.com/spegel-org/spegel) - In-cluster OCI registry mirror to save some bandwidth.
7. [Flux](https://fluxcd.io/) - After this point Flux manages the state of the cluster via manifests in the repo.

All of these get installed with a single command from the [bootstrap Taskfile](https://github.com/mchestr/home-cluster/blob/main/.taskfiles/bootstrap/Taskfile.yml#L20):

```bash
task bootstrap:apps
```

This applies [bootstrap resources](https://github.com/mchestr/home-cluster/blob/main/bootstrap/resources.yaml) for 1Password and Cloudflare tunnel, then installs everything via [helmfile](https://helmfile.readthedocs.io/en/latest/).
