# Home Network Setup

Some random thoughts and documentation for my current home network setup.

- `192.168.1.0/24` > LAN
- `192.168.33.0/24` > Wireguard
- `10.0.10.0/24` > IoT (VLAN10)
- `10.0.20.0/24` > Cilium LoadBalancer Pool
- `10.0.40.0/24` > Servers

# Cilium Loadbalancer & BGP

[Cilium is used](https://docs.cilium.io/en/stable/network/lb-ipam/) to support the
Loadbalancer service type in my cluster. Cilium manages the `10.0.20.0/24` subnet
to allocate IPs. BGP is configured between Cilium running on my cluster with my UDMP
to provide routing for the rest of my home network.

# ThunderBolt Ring Network

`169.254.255.0/24` is used for the ring network, each node is connected to the other
2 nodes using the 2 thunderbolt ports on each computer.

![thunderboltconnection](../assets/thunderbolt.png)

### Validating Configuration

Spin up 3 node-shells.

```
task kubernetes:node-shell NODE=m0
task kubernetes:node-shell NODE=m1
task kubernetes:node-shell NODE=m2
```

Inspect routes are configured correctly

```
ip r | grep '169.254.255'
```

Ping each node and ensure it works

```
# From m0
ping 169.254.255.11
ping 169.254.255.12
...
```
