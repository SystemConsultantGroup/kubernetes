# Argo CD

This Application owns the Argo CD chart, its repository values, namespace
metadata, and public route at `https://argocd.platform.scg.sh`.

## Bootstrap and ownership

`k install argocd` renders and applies the same pinned chart and values before
creating the root Application. Once the root reconciles, this Application
assumes ongoing ownership with pruning and self-healing. Update
`argocd.version`, this Application revision, and chart values through Git rather
than rerunning the bootstrap command for an ordinary upgrade.

## Routing

The `argocd` HTTPRoute attaches to the public Gateway's `platform-https`
listener and forwards to `argocd-server` on Service port 80. TLS terminates at
the Gateway with the shared `*.platform.scg.sh` certificate.

Argo CD's Helm values create the separate ApplicationSet webhook route for
`/applicationset-webhook`. The main API webhook remains available at
`/api/webhook`. Both GitHub webhooks use the same encrypted Secret but notify
different controllers.

## Reconciliation

The platform Application runs at sync wave 3, after the Gateway and wildcard
certificate Applications have started reconciliation. Change the hostname,
parent listener, Helm domain, and GitHub webhook configuration together.
