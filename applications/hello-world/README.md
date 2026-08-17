# hello-world

This is the example managed application in the repository. It contains one
workload named `hello-world`.

## Files

- [`meta.yaml`](meta.yaml) configures an HTTP workload listening on container
  port 8080, with a readiness probe at `/`, and the public hostname
  `hello.world.scg.sh`.
- [`instances/production.yaml`](instances/production.yaml) pins the production
  source commit and nginx image digest.

The directory uses the managed application layout. Argo CD discovers its
production instance and renders it with the shared chart in
[`../../argocd/charts/application/`](../../argocd/charts/application/).

Use this directory as a reference when adding another managed application. Do
not copy its image lock without replacing both the source revision and image
with the pair produced by the intended build.
