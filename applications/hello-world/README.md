# hello-world

This directory is the repository's minimal public HTTP application example.
It contains one workload named `fe`.

## Files

- [`meta.yaml`](meta.yaml) configures a container port of 8080 and the public
  hostname `hello.world.scg.sh`.
- [`instances/production.yaml`](instances/production.yaml) pins the production
  source commit and image digest.
- [`instances/testing.yaml`](instances/testing.yaml) pins the testing instance
  to the same immutable build.
- [`instances/preview/fe/1.yaml`](instances/preview/fe/1.yaml) defines preview
  `1` using the same immutable build.

The generated identities are:

```text
hello-world-production
hello-world-testing
hello-world-preview-fe-1
```

The first two names are the production and testing Argo CD Applications, Helm
releases, and namespaces.
The preview name is the corresponding preview identity.
Each rendered instance creates a Deployment and Service named `hello-world-fe`.

Use this directory as a minimal reference when adding a managed application.
Replace the source revision and image digest with the pair produced by the
intended build.
Testing and preview may reuse production's lock when they intentionally deploy
the same build.

The shared schema and renderer are documented in
[`../../argocd/charts/application/`](../../argocd/charts/application/).
