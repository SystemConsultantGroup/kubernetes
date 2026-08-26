# Temporary E2S Vault OIDC DNS fix

Date: 2026-08-26

## Status

A temporary desired-state fix pins public Gateway DNS records to SCC while the
E2S attachment rehearsal remains incomplete. The fix is present in the working
tree but has not been applied to the cluster by this change.

Changed:

- `argocd/platform/gateway/gateway.yaml` now sets the Gateway annotation:

  ```yaml
  external-dns.alpha.kubernetes.io/target: "115.145.134.232"
  ```

This is a temporary safety boundary, not an E2S networking fix. Remove or
replace it after a stable external load-balancer or an explicitly validated
multi-node public-ingress design is available.

## Incident

Vault OIDC login through GitHub via Argo CD Dex failed during the authorization
code exchange with:

```text
503 Service Unavailable
upstream connect error or disconnect/reset before headers.
reset reason: connection timeout
```

The failure was caused by public DNS publishing both node addresses while E2S
was not yet able to serve the Gateway path reliably:

- `115.145.134.232` (SCC) returned HTTP `200` for
  `https://argocd.platform.scg.sh/api/dex/.well-known/openid-configuration`;
- `115.145.172.19` (E2S) returned HTTP `503` with the upstream connection
  timeout; and
- DNS from the Vault pod resolved `argocd.platform.scg.sh` to E2S first.

Consequently, Vault's server-side OIDC token exchange could select E2S and
fail, while selecting SCC succeeded.

## Why the existing selector did not prevent this

Cilium has the configured host-network listener selector
`gateway.scg.sh/listener=true`, and only SCC currently has that label. The
selector controls where the Gateway listener is exposed, but Cilium still
reported both node addresses in `Gateway/public.status.addresses`. ExternalDNS
uses Gateway addressing for its targets, so the selector alone did not provide
the required DNS safety boundary.

The target annotation is deliberately placed on the `Gateway`, where the
Gateway API ExternalDNS source reads target annotations. It is not placed on an
HTTPRoute. The deployed ExternalDNS `v0.21.0` expects the `alpha` annotation
name; the newer non-alpha spelling was initially tried but was ignored, so DNS
continued to publish both addresses until this correction.

## Validation after reconciliation

After this change is committed and Argo CD reconciles it, verify without
uncordoning or changing E2S:

```bash
dig +short argocd.platform.scg.sh
kubectl get gateway public -n gateway-system -o jsonpath='{.status.addresses}'
kubectl -n vault exec vault-0 -- \
  wget --no-check-certificate --timeout=10 --tries=1 -q -O - \
  https://argocd.platform.scg.sh/api/dex/.well-known/openid-configuration
```

The public DNS record must contain only SCC before retrying Vault OIDC. The
OIDC discovery response must identify the Argo CD Dex issuer and return
successfully from the Vault pod.

This does not close the E2S rehearsal. UDP VXLAN `8472` must still be permitted
bidirectionally and the privileged Cilium connectivity suite must pass before
E2S is uncordoned or used for local storage and PXC tests.

## Rollback and removal

Rollback the temporary fix by removing the
`external-dns.alpha.kubernetes.io/target` annotation from
`argocd/platform/gateway/gateway.yaml`, then allowing Argo CD to reconcile the
removal. Do not remove it while E2S still returns the observed
Gateway `503` response.

Remove this temporary pin only after all of the following are true:

- E2S cross-node Cilium connectivity passes in both directions;
- E2S Gateway traffic is explicitly tested;
- the intended public-ingress address strategy is documented; and
- DNS failover or load-balancer behavior is validated.
