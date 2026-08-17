# Argo CD configuration

This directory contains the GitOps root, platform Applications, ApplicationSets,
projects, and shared managed-application chart. Argo CD follows `main` and
reconciles with pruning and self-healing enabled.

## Bootstrap

After Kubernetes and Cilium are available, an operator runs:

```bash
k install argocd
```

The command installs the pinned Argo CD chart, creates bootstrap secrets from
encrypted values, and applies [`root-application.yaml`](root-application.yaml).
The root Application then reconciles this directory. The initial admin secret
is removed; access uses the GitHub OAuth configuration in [`values.yaml`](values.yaml).

`values.yaml` is used by the explicit Helm installation. Its OAuth client
secret is read from encrypted bootstrap data and must not be committed here.

## Directory map

- [`application-sets/`](application-sets/) discovers managed, preview, and
  custom applications.
- [`charts/`](charts/) contains the shared managed-application renderer.
- [`platform/`](platform/) defines Applications for cluster services.
- [`projects/`](projects/) defines source, destination, and resource permissions.
- [`kustomization.yaml`](kustomization.yaml) assembles the root resources.
- [`root-application.yaml`](root-application.yaml) is applied during bootstrap.

## Change guidance

Application owners should normally edit [`../applications/`](../applications/).
Changes here can affect multiple workloads, namespaces, or cluster-wide
services. Review ApplicationSet discovery, project permissions, sync waves,
secrets, and cluster-scoped resources before merging.

Change desired state in Git rather than editing Argo CD-managed resources in the
cluster. Re-run `k install argocd` only when explicitly changing the installed
Argo CD configuration or recovering its bootstrap state.
