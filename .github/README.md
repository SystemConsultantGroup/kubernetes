# Application delivery workflows

Application repositories use the reusable [`build-image.yaml`](workflows/build-image.yaml) workflow. It builds the root `Dockerfile` with the repository root as its context, publishes an immutable image, records build provenance, and dispatches [`apply.yaml`](workflows/apply.yaml) in this repository.

`apply.yaml` serializes instance changes through the `instance-updates` queue. It sets production or testing workload locks, creates and updates preview locks, and removes preview locks when pull requests close. It never accesses the cluster; Argo CD observes the resulting commit to `main`.

## Application workflow

Add a small workflow to the application repository and pin the reusable workflow to a full Kubernetes commit:

```yaml
name: Container

on:
  pull_request:
    types:
      - opened
      - reopened
      - synchronize
      - closed
  push:
    branches:
      - main
      - testing

permissions:
  attestations: write
  contents: read
  id-token: write
  packages: write

jobs:
  build-image:
    uses: SystemConsultantGroup/kubernetes/.github/workflows/build-image.yaml@0123456789abcdef0123456789abcdef01234567
    with:
      application: example
      workload: fe
      image: ghcr.io/systemconsultantgroup/kubernetes-example
    secrets:
      KUBERNETES_APP_ID: ${{ secrets.KUBERNETES_APP_ID }}
      KUBERNETES_APP_PRIVATE_KEY: ${{ secrets.KUBERNETES_APP_PRIVATE_KEY }}
```

## Branch and instance mapping

The mapping uses exact branch names. It is not based on the order of the branches in the workflow:

| Application event | Instance change |
| --- | --- |
| Push to `main` | Update production |
| Push to `testing` | Update testing |
| Open or update a same-repository pull request | Create or update that pull request's preview |
| Close a same-repository pull request | Remove that pull request's preview |

A push from any branch other than `main` or `testing` is rejected. Pull requests build GitHub's proposed merge commit so previews exercise the code that would result from merging. Fork pull requests are rejected and `pull_request_target` is not supported.

Application tests can run in a separate job before `build-image`. A pull-request closure must still call the reusable workflow so it can remove the preview lock.

## Registry configuration

The `image` input selects authentication from its fully qualified repository:

- `ghcr.io` uses the caller's `GITHUB_TOKEN` and needs `packages: write`;
- `docker.io` needs explicitly forwarded `DOCKERHUB_USERNAME` and `DOCKERHUB_TOKEN` secrets.

Images are deployed only by digest. Human-readable commit tags are published for inspection but are never written to instance locks.

## Dispatch authorization

Application repositories need `KUBERNETES_APP_ID` and `KUBERNETES_APP_PRIVATE_KEY`. The corresponding GitHub App must be installed only on this repository and needs `Actions: write`. Its token can dispatch `apply.yaml` but cannot modify repository contents.

The apply workflow treats every dispatch as untrusted. It limits changes to the application and workload already associated with the source and image repositories in the production lock. Its own `GITHUB_TOKEN` performs the resulting commit.
