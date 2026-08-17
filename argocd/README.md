# Argo CD configuration

This directory contains the GitOps resources that connect the repository to
the cluster. Argo CD follows the `main` branch and reconciles the root
Application with pruning and self-healing enabled.

## Bootstrap lifecycle

`k install argocd` installs the pinned Argo CD chart, creates the bootstrap
secrets from encrypted repository values, and applies
[`root-application.yaml`](root-application.yaml). The root Application then
reconciles this directory.

[`values.yaml`](values.yaml) is used by the explicit Helm installation. It
contains Argo CD URL, GitHub OAuth, and RBAC configuration. The OAuth client
secret is supplied from encrypted bootstrap data and must not be added to this
file.

After bootstrap, change desired state in Git rather than editing Argo CD or
platform resources directly in the cluster.

## Directory map

- [`application-sets/`](application-sets/) discovers managed, preview, and
  custom applications.
- [`charts/`](charts/) contains the shared Helm chart for managed applications.
- [`platform/`](platform/) defines Argo CD Applications for cluster platform
  components.
- [`projects/`](projects/) defines Argo CD source, destination, and resource
  permissions.
- [`kustomization.yaml`](kustomization.yaml) assembles the root resources.
- [`root-application.yaml`](root-application.yaml) is the initial root
  Application applied during Argo CD installation.

## Change guidance

Application owners should normally edit [`../applications/`](../applications/)
rather than this directory. Changes to ApplicationSets, projects, the shared
chart, or platform Applications affect multiple workloads or cluster-wide
services and require operator review.

Changes to [`values.yaml`](values.yaml) are bootstrap changes. Re-run
`k install argocd` only when explicitly changing the installed Argo CD
configuration; ordinary GitOps resources should be changed through Git and
allowed to reconcile.
