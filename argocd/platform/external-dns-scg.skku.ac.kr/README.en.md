[한국어](README.md) | English

# Inactive RFC2136 DNS example

This directory is reference material for a possible ExternalDNS instance for
`scg.skku.ac.kr`. Files end in `.example`, are not included by the Argo CD root,
and do not affect the cluster.

Do not activate the example by renaming files alone. A rollout requires an
approved RFC2136 endpoint and TSIG secret, a unique TXT owner ID, narrow domain
filters, an Argo CD Application included in the root Kustomization, and a review
of record ownership alongside the active Cloudflare instance.

Keep credentials out of this directory. If the design is approved, document its
record ownership and operating procedure here before enabling reconciliation.
