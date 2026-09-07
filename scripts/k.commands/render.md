# render

Renders state-derived schemas and Kubernetes manifests.

## Usage

```bash
k render
k render <command>
```

Running `k render` with no subcommand updates the committed application schema
and then recreates the ignored `.rendered/` manifest tree.

## Subcommands

- `application-schemas` renders or checks the committed managed-application
  schema.
- `manifests` renders bootstrap, GitOps root, platform, and application
  manifests for inspection.

Rendering does not contact or change the live cluster. It downloads artifacts
at the versions pinned in `state.yaml`, so network access is required.
