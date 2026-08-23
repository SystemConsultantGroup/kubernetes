[한국어](README.md) | English

# ExternalDNS for scg.sh

This component publishes DNS records for Gateway API HTTPRoutes under `scg.sh`
through Cloudflare. It watches Gateway routes, including ListenerSets, and runs
with the chart version pinned in [`../../../state.yaml`](../../../state.yaml).

## Ownership and scope

ExternalDNS is restricted by `domainFilters` to `scg.sh`. It uses the TXT
registry with owner ID `scg.sh`, so it manages only records carrying its
ownership marker. Policy is `sync`: removing an owned desired record can remove
it from Cloudflare.

`k install argocd` creates `external-dns/cloudflare-api-token` from encrypted
bootstrap values. The token needs zone-read and DNS-edit access for the relevant
zone. Do not put it in `values.yaml`.

The public Gateway and application chart use annotations to publish wildcard
platform, testing, and preview records. A production domain marked
`external: true` carries the exclusion annotation and remains the responsibility
of its external DNS operator.

## Changes

Keep the chart pin synchronized with `external-dns.version` in `state.yaml`.
Review `domainFilters`, TXT ownership, source kinds, and deletion behavior before
changing this component. Inspect ExternalDNS's planned endpoint log before a
DNS migration; do not use direct provider edits as durable desired state for
records this controller owns.
