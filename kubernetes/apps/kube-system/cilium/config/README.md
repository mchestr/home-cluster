# Cilium Network Configuration

[Cilium](https://cilium.io/) is used as the CNI (Container Network Interface) for this Kubernetes cluster. This document contains configuration details for network integration.

## UniFi BGP Configuration

The following BGP configuration needs to be applied to the UniFi router to establish BGP peering with Cilium in the Kubernetes cluster:

```sh
router bgp 64513
  bgp router-id 10.0.40.1
  no bgp ebgp-requires-policy

  neighbor k8s peer-group
  neighbor k8s remote-as 64514

  neighbor 10.0.40.10 peer-group k8s
  neighbor 10.0.40.11 peer-group k8s
  neighbor 10.0.40.12 peer-group k8s

  address-family ipv4 unicast
    neighbor k8s next-hop-self
    neighbor k8s soft-reconfiguration inbound
  exit-address-family
exit
```

This configuration establishes BGP peering between the UniFi router (AS 64513) and the Kubernetes nodes (AS 64514), enabling dynamic route advertisement for Kubernetes services.
