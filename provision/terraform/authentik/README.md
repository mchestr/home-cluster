# Authentik Terraform

Directory contains terraform used to manage Authentik.

## Initialization

Currenty the latest version of [Authentik Terraform Provider (2022.4.1)](https://registry.terraform.io/providers/goauthentik/authentik/latest)
does not have a data provider for the embedded Authentik Outpost, so we need to import it first. You can find the pk of the resources via the API.

```bash
terraform import authentik_service_connection_kubernetes.local "<authentik_service_connection_kubernetes_uuid>"
terraform import authentik_outpost.outpost "<authentik_outpost_uuid>"
```

We can now have Terraform add providers to the embedded outpost without manual intervention.

### Secrets

I am experimenting with Authentiks `Authorization` header forwarding with some apps, it probably creates a circular dependency on the App and Authentik, but it works for now. All secrets are defined in [secret.sops.yaml](./secret.sops.yaml)

The idea behind this is mostly to experiment, but also was thinking it may be more secure if there was a malicious app in my cluster, as it could bypass Authentik. However this is probably better solved with network policies in the future, and would be easier to manage via GitOps.

## Overview

I am not an expert user of Terraform, so I just split the resources across multiple files as they are grouped in the Terraform provider.

At a high level:

1. Applications are defined in [application.tf](./applications.tf) and groups are assigned.
2. Providers are created from the different application groups depending on their auth strategy.
3. Applications are created for all defined apps, then policies are assigned depending on how they are grouped.
4. Users are created and added to the groups.

Additionally, I created a custom [authorization_flow](./flows.tf) to add a [captcha stage](https://goauthentik.io/docs/flow/stages/captcha/) to make the setup more secure (? :fingers_crossed: ). This custom stage is then assigned to the [tenant](./system.tf).
