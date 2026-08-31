[한국어](README.md) | English

# Gateway API definitions

This Application reconciles the upstream standard Gateway API CRDs at the
version pinned in `state.yaml`. Envoy Gateway and the platform Gateway depend
on these cluster-scoped definitions; Cilium no longer reconciles Gateway API
resources.

The initial CRDs are rendered from the official release artifact and applied by
`k install cilium` because Argo CD cannot run before Cilium. After the root
Application is created, Argo CD owns the definitions directly from the matching
upstream Git tag.

Update the state pin and this Application revision together. Review conversion,
storage-version, and Cilium compatibility notes before changing CRD versions.
