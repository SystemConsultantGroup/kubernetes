# Argo CD projects

Argo CD Projects restrict the repositories, destinations, and Kubernetes
resources available to an Application.
These files are an authorization boundary and are applied before generated and
platform Applications.

## Projects

| Project | Sources | Resource scope |
| --- | --- | --- |
| `applications` | This repository | Any namespace, `Namespace` plus all namespaced kinds |
| `platform` | This repository and approved upstream platform chart and manifest repositories | Any namespace and cluster-scoped kinds required by platform services |

See [`applications.yaml`](applications.yaml) and [`platform.yaml`](platform.yaml)
for the exact allowlists. The `applications` destination must be broad enough
for generated namespaces, so repository layout checks and platform review also
enforce that each custom application targets only its own namespace. The
AppProject is not a substitute for reviewing merged desired state.

## Editing guidance

Treat project changes as authorization changes.
When adding a source, verify that the repository is required.
When adding a destination or resource kind, make the narrowest change that
supports the component.
Do not use a project change to bypass review or grant application workloads
platform-only access.

Both projects use sync wave `0`; ApplicationSets and platform Applications run
later.
Keep that ordering intact unless the bootstrap dependency graph is changed
deliberately.
