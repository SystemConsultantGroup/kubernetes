[한국어](README.md) | English

# Argo CD configuration

This directory contains the GitOps root, platform Applications, ApplicationSets,
projects, and shared managed-application chart.
Argo CD follows `main` and reconciles with pruning and self-healing enabled.

## Bootstrap

After Kubernetes and Cilium are available, an operator runs:

```bash
k install argocd
```

The command renders and applies the pinned Argo CD chart, creates bootstrap
Secrets from encrypted values, and applies
[`root-application.yaml`](root-application.yaml). The root Application then
reconciles this directory and assumes ongoing ownership of Argo CD itself,
Cilium, Gateway API, and the remaining platform desired state. The initial admin
Secret is removed; access uses the GitHub OAuth configuration in
[`values.yaml`](values.yaml).

`values.yaml` is shared by bootstrap rendering and the Argo CD Application. Its
OAuth client secret is read from encrypted bootstrap data and must not be
committed here.

## Access and refresh

The normal GitHub team has read-only Argo CD access.
Application changes are made in Git and automated sync remains enabled for the
controllers.

GitHub push webhooks use these paths on `argocd.platform.scg.sh`:

- `/api/webhook` refreshes the Argo CD API server;
- `/applicationset-webhook` refreshes the ApplicationSet controller.

The second path is rewritten internally to the ApplicationSet webhook endpoint.
Create both GitHub repository webhooks with the same secret and the push event.
Git polling remains enabled at 180 seconds as a fallback.
Webhook delivery uses `application/json` and the encrypted
`ARGOCD_GITHUB_WEBHOOK_SECRET` value.

## Directory map

- [`application-sets/`](application-sets/README.en.md) discovers managed, preview,
  and custom applications.
- [`charts/`](charts/README.en.md) contains the shared managed-application renderer.
- [`platform/`](platform/README.en.md) defines Applications for cluster services.
- [`projects/`](projects/README.en.md) defines source, destination, and resource
  permissions.
- [`kustomization.yaml`](kustomization.yaml) assembles the root resources.
- [`root-application.yaml`](root-application.yaml) is applied during bootstrap.

## Change guidance

Application owners should normally edit
[`../applications/`](../applications/README.en.md).
Changes here can affect multiple workloads, namespaces, or cluster-wide
services.
Review ApplicationSet discovery, project permissions, sync waves, secrets, and
cluster-scoped resources before merging.

Change desired state in Git rather than editing Argo CD-managed resources in the
cluster.
Use Git for ordinary Argo CD configuration and chart upgrades. Re-run
`k install argocd` only when recovering bootstrap state before GitOps is
available.
