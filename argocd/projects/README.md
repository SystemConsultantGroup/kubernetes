# Argo CD projects

Argo CD Projects define which repositories, destinations, and Kubernetes
resources an Application may use. These files are a security boundary for the
GitOps installation and are applied before the generated Applications.

## Projects

### `applications`

[`applications.yaml`](applications.yaml) permits the repository's application
sources to deploy to Kubernetes namespaces. It permits Namespace as a cluster
resource and all namespaced resource kinds.

### `platform`

[`platform.yaml`](platform.yaml) permits the repository and the external Helm
repositories used by cert-manager and ExternalDNS. It can deploy to any
namespace and permits cluster-scoped resources required by platform services.

## Editing guidance

Review project changes as authorization changes, not ordinary configuration.
When adding an Application source, verify its repository is listed in the
project. When adding a destination or resource kind, make the narrowest change
that supports the component.

Do not use a project change to bypass review or to grant an application access
to platform-only resources. The root Kustomization applies both projects with
sync wave `0`; generated and platform Applications depend on them.
