[한국어](README.md) | English

# Public Gateway

This directory defines the Cilium-backed `gateway-system/public` Gateway and
its ingress policy for platform services and managed applications. Cilium and
the pinned Gateway API CRDs are bootstrapped by `k install cilium`, then
reconciled by their own Argo CD Applications.

## Listeners

| Listener | Hostname | Certificate |
| --- | --- | --- |
| `platform-https` | `*.platform.scg.sh` | `platform-wildcard-tls` |
| `testing-https` | `*.testing.scg.sh` | `application-wildcards-tls` |
| `preview-https` | `*.preview.scg.sh` | `application-wildcards-tls` |

cert-manager creates the referenced Secrets in `gateway-system`. Managed
production domains attach through ListenerSets created by the application
chart, with separate certificates where the platform owns TLS.

## Client network boundary

The `public-gateway-ingress` Cilium policy permits internet access to testing
and preview hosts only from `115.145.150.0/24`. Traffic originating inside the
cluster remains allowed. Platform hosts remain public, and the
`application-routing-policies` ApplicationSet generates exact public-host rules
for managed production domains. Requests from other internet source addresses
to testing or preview hosts receive an Envoy `403 Forbidden` response.

The policy selects Cilium's reserved ingress identity. Preserve both the CIDR
rule and the absence of public testing or preview host rules when changing it.
The explicit production hosts in the base policy are rollout safeguards for the
applications that existed when enforcement was introduced; generated policies
supply rules for new production hosts.

## Namespace boundary

Routes and ListenerSets may attach only from namespaces labeled:

```yaml
gateway.scg.sh/public: "true"
```

Managed application namespaces receive this label from their ApplicationSet.
The selector is part of the public-exposure boundary; do not broaden it merely
to make an unreviewed route attach.

## Changes and diagnosis

A route must have an accepted parent, a matching listener hostname, and a valid
backend reference before it serves traffic. Check Gateway and route conditions
before inspecting DNS. DNS publication and certificate issuance are separate
controllers documented under
[`../external-dns-scg.sh/`](../external-dns-scg.sh/README.en.md) and
[`../cert-manager/`](../cert-manager/README.en.md).
