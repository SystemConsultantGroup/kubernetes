# Argo CD route resources

This directory adds the namespace metadata and public route that expose the Argo
CD server at `https://argocd.platform.scg.sh`. The Argo CD Helm release itself
is installed and configured by `k install argocd` using
[`../../values.yaml`](../../values.yaml).

## Routing

The `argocd` HTTPRoute attaches to the public Gateway's `platform-https`
listener and forwards to `argocd-server` on Service port 80. TLS terminates at
the Gateway with the shared `*.platform.scg.sh` certificate.

Argo CD's Helm values create the separate ApplicationSet webhook route for
`/applicationset-webhook`. The main API webhook remains available at
`/api/webhook`. Both GitHub webhooks use the same encrypted secret but notify
different controllers.

## Reconciliation

The platform Application runs at sync wave 3, after the Gateway and wildcard
certificate. Argo CD manages these resources from `main` with pruning and
self-healing enabled. Change the hostname, parent listener, Helm domain, and
GitHub webhook configuration together.
