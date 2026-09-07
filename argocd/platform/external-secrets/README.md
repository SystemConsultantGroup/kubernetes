# External Secrets Operator

This component installs External Secrets Operator for managed application
secrets. The chart version is pinned in
[`../../../state.yaml`](../../../state.yaml), and its CRDs are installed by the
Helm release.

## Supported scope

The deployment processes namespaced `SecretStore` and `ExternalSecret`
resources. Cluster-wide stores, generators, push secrets, and
ClusterExternalSecrets are disabled. This keeps the application integration
namespaced and avoids exposing a cluster-scoped secret interface.

The managed application chart creates a namespaced Vault SecretStore and one
ExternalSecret per workload when the platform-owned integration gate is enabled.
Application metadata does not configure Vault servers, roles, or paths. See the
[Vault contract](../vault/README.md) and [application chart
documentation](../../charts/application/README.md).

## Changes

Keep the chart pin synchronized with `external-secrets.version` in `state.yaml`.
Treat enabling another controller or cluster-scoped CRD as an authorization
change. Validate CRD upgrades and conversion compatibility before changing the
major chart version; deleting an ExternalSecret can also remove the Kubernetes
Secret it owns.
