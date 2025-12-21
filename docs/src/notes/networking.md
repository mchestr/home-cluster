# Home Network Setup

Some notes on my current home network setup.

## Network Diagram

```mermaid
flowchart TB
    subgraph Internet
        WAN[("🌐 Internet")]
        CF[Cloudflare Tunnel]
    end

    subgraph Network["Network Infrastructure"]
        UDM["UDM Pro Max<br/>Gateway/Router<br/>192.168.1.1 | 10.0.40.1"]
        AGG["USW-Pro-Aggregation<br/>Switch"]
        POE["USW-Pro-Max-24-PoE<br/>Switch"]
        AP["UAP-AC-Lite<br/>WiFi AP"]
    end

    subgraph Servers["Kubernetes Cluster (10.0.40.0/24)"]
        M0["m0 - MS-01<br/>i9-13900H | 96GB<br/>10.0.40.10 | 169.254.255.10"]
        M1["m1 - MS-01<br/>i9-13900H | 96GB<br/>10.0.40.11 | 169.254.255.11"]
        M2["m2 - MS-01<br/>i9-13900H | 96GB<br/>10.0.40.12 | 169.254.255.12"]

        subgraph TB_Ring["Thunderbolt Ring (169.254.255.0/24)"]
            CEPH[("Rook-Ceph<br/>3x 2TB NVMe")]
        end
    end

    subgraph Storage["Storage (10.0.40.0/24)"]
        NAS["UNAS Pro 8<br/>4x 28TB (112TB raw)<br/>10.0.40.x"]
    end

    subgraph HomeLAN["Home Network (192.168.1.0/24)"]
        Devices["Computers, TVs,<br/>Phones, Tablets, etc."]
    end

    subgraph IoT["IoT VLAN 10 (10.0.10.0/24)"]
        HA["Home Assistant<br/>10.0.10.250"]
        Frigate["Frigate NVR<br/>10.0.10.239"]
        ESPHome["ESPHome<br/>10.0.10.245"]
        Zigbee["Zigbee2MQTT"]
        ZWave["Z-Wave JS UI"]
    end

    subgraph Services["K8s Services (10.0.20.0/24)"]
        MQTT["EMQX MQTT<br/>10.0.20.50"]
        Plex["Plex<br/>10.0.20.110"]
        Jellyfin["Jellyfin<br/>10.0.20.70"]
        PG["PostgreSQL<br/>10.0.20.17"]
        Envoy["Envoy Gateway<br/>External: 10.0.20.100<br/>Internal: 10.0.20.200"]
    end

    subgraph Mgmt["Management"]
        PiKVM["PiKVM V4 Mini"]
        UPS["CyberPower UPS"]
        PDU["UniFi PDU Pro"]
    end

    WAN --> UDM
    CF -.-> UDM
    UDM --> AGG
    AGG --> POE
    POE --> AP
    POE --> Devices
    AP -.->|"WiFi"| Devices
    AGG -->|"10Gb LACP"| M0
    AGG -->|"10Gb LACP"| M1
    AGG -->|"10Gb LACP"| M2
    M0 <-->|"TB4"| CEPH
    M1 <-->|"TB4"| CEPH
    M2 <-->|"TB4"| CEPH
    AGG -->|"10Gb"| NAS
    UDM -->|"VLAN 10"| IoT
    UDM <-.->|"BGP<br/>ASN 64513 ↔ 64514"| Servers
    Servers --> Services
    PiKVM --> Servers
    UPS --> PDU
    PDU --> Servers

    classDef router fill:#e74c3c,color:white
    classDef switch fill:#3498db,color:white
    classDef server fill:#2ecc71,color:white
    classDef storage fill:#f39c12,color:white
    classDef iot fill:#9b59b6,color:white
    classDef service fill:#1abc9c,color:white
    classDef tbring fill:#e67e22,color:white
    classDef homelan fill:#95a5a6,color:white

    class UDM router
    class AGG,POE,AP switch
    class M0,M1,M2 server
    class NAS storage
    class CEPH tbring
    class HA,Frigate,ESPHome,Zigbee,ZWave iot
    class MQTT,Plex,Jellyfin,PG,Envoy service
    class Devices homelan
```

## Subnets

- `192.168.1.0/24` - LAN
- `192.168.33.0/24` - Wireguard
- `10.0.10.0/24` - IoT (VLAN10)
- `10.0.20.0/24` - Cilium LoadBalancer Pool
- `10.0.40.0/24` - Servers

## Cilium LoadBalancer & BGP

I use [Cilium](https://docs.cilium.io/en/stable/network/lb-ipam/) to support LoadBalancer services in the cluster. Cilium manages the `10.0.20.0/24` subnet for IP allocation. BGP is configured between Cilium and my UDM Pro to provide routing for the rest of my home network.

## Ingress Architecture

```mermaid
flowchart LR
    subgraph Internet
        Users["External Users"]
        ExtDNS["External DNS<br/>(Cloudflare)"]
        CFEdge["Cloudflare Edge<br/>*.chestr.dev"]
    end

    subgraph HomeNet["Home Network"]
        HomeUsers["Internal Users"]
        UDM["UDM Pro Max<br/>ASN 64513"]
    end

    subgraph Nodes["Cluster Nodes (m0, m1, m2)"]
        subgraph K8s["Kubernetes"]
            subgraph Gateways["Envoy Gateways"]
                ExtGW["External Gateway<br/>10.0.20.200"]
                IntGW["Internal Gateway<br/>10.0.20.100"]
            end

            CFTunnel["Cloudflared<br/>Tunnel Pod"]

            subgraph Apps["Application Pods"]
                ExtApps["External Apps<br/>Plex, Home Assistant, Radicale"]
                IntApps["Internal Apps<br/>Frigate, Sonarr, Radarr"]
            end

            ExtDNSOp["External-DNS Operator"]
        end
    end

    Users --> ExtDNS
    ExtDNS -->|HTTPS| CFEdge
    CFEdge -->|Tunnel| CFTunnel
    CFTunnel --> ExtGW
    ExtGW --> ExtApps

    HomeUsers --> UDM
    UDM --> ExtGW
    UDM --> IntGW
    IntGW --> IntApps

    ExtDNSOp -.->|Sync| ExtDNS
    ExtDNSOp -.->|Sync| UDM

    Nodes <-->|"BGP<br/>ASN 64514"| UDM

    classDef cloudflare fill:#f38020,color:white
    classDef gateway fill:#1abc9c,color:white
    classDef extapps fill:#3498db,color:white
    classDef intapps fill:#9b59b6,color:white
    classDef router fill:#e74c3c,color:white

    class CFEdge,CFTunnel,ExtDNS cloudflare
    class ExtGW,IntGW gateway
    class ExtApps extapps
    class IntApps intapps
    class UDM router
```

### Traffic Flows

**External Traffic (Internet → Services):**
1. User requests `app.chestr.dev`
2. Cloudflare DNS resolves to Cloudflare Edge
3. Cloudflare routes through tunnel to Cloudflared pod
4. Routes to External Envoy Gateway (10.0.20.200)
5. Gateway routes to appropriate pod based on hostname

**Internal Traffic (Home Network → Services):**
1. User requests `app.chestr.dev`
2. UDM DNS resolves to gateway IP (10.0.20.100 or 10.0.20.200)
3. Envoy Gateway routes to pod
4. Full access to all services

**Split Horizon DNS:**
- External-DNS operator syncs HTTPRoute hostnames to both Cloudflare and UDM
- External users resolve to Cloudflare (proxied through tunnel)
- Internal users resolve directly to Gateway LB IPs via UDM
- BGP advertises LB IPs (10.0.20.0/24) from cluster nodes to UDM

## ThunderBolt Ring Network

`169.254.255.0/24` is used for the ring network. Each node is connected to the other 2 nodes using the 2 thunderbolt ports on each computer.

![thunderbolt connection](../assets/thunderbolt.png)

### Validating Configuration

Spin up 3 node-shells:

```bash
task kubernetes:node-shell NODE=m0
task kubernetes:node-shell NODE=m1
task kubernetes:node-shell NODE=m2
```

Check routes are configured correctly:

```bash
ip r | grep '169.254.255'
```

Ping each node and make sure it works:

```bash
# From m0
ping 169.254.255.11
ping 169.254.255.12
# etc...
```
