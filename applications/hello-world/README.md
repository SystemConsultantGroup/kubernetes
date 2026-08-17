# hello-world

This directory is the repository's complete managed application example. It
contains one HTTP workload named `hello-world`.

## Files

- [`meta.yaml`](meta.yaml) configures port 8080, a readiness probe at `/`, and
  the public hostname `hello.world.scg.sh`.
- [`instances/production.yaml`](instances/production.yaml) pins the source
  commit and nginx image digest for production.

Use this directory as a reference for a new managed application. Replace both
the source revision and image digest with the pair produced by the intended
build; do not reuse this example's lock.

The shared renderer is documented in
[`../../argocd/charts/application/`](../../argocd/charts/application/).
