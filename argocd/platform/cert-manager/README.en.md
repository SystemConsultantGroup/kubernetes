[한국어](README.md) | English

# cert-manager

This component installs cert-manager and the certificates used by the public
Gateway. It uses the chart version pinned in [`../../../state.yaml`](../../../state.yaml)
and enables both CRD installation and Gateway API support.

## Issuance

The `zerossl-cloudflare` ClusterIssuer completes ZeroSSL ACME DNS-01 challenges
through Cloudflare. `k install argocd` creates these required Secrets before the
Application reconciles:

- `cert-manager/cloudflare-api-token`;
- `cert-manager/zerossl-eab`.

The manifests issue two Secrets in `gateway-system`:

| Secret | Names covered |
| --- | --- |
| `platform-wildcard-tls` | `*.platform.scg.sh` |
| `application-wildcards-tls` | `*.testing.scg.sh`, `*.preview.scg.sh` |

Managed production domains receive separate Certificates from the application
chart unless they are marked external.

## Changes and diagnosis

Keep the chart pin synchronized with `cert-manager.version` in `state.yaml`.
Changing the issuer, ACME account, DNS provider, or wildcard names is a
platform-wide certificate migration. Verify the issuer before diagnosing a
Certificate, then its CertificateRequest, Order, and Challenge resources.
Never place the EAB HMAC key or Cloudflare token in these manifests or values.
