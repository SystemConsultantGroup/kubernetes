# Repository instructions

## Scope and intent

These instructions apply to the entire repository.
This repository is the declarative source of truth for one live Kubernetes
cluster.
Argo CD reconciles `main` with pruning and self-healing enabled, so assume that
merged changes under `applications/` or `argocd/` can affect live workloads
automatically.

Keep changes focused, preserve unrelated work, and use the tools supplied by
`nix develop` rather than adding ad hoc dependencies.

When improving this repository, prioritize outcomes in this order:

1. ease of use and readability for application developers and platform
   engineers;
1. correctness;
1. concision and organization;
1. clarity; and
1. other concerns.

Evaluate both audiences explicitly. Do not improve one workflow by making the
other need platform-only access or unnecessary implementation knowledge.

## Documentation

- Keep the root `README.md` a short landing page for application owners and
  platform operators.
- Write for the person completing a task: put the common workflow, choice, or
  safety boundary before implementation detail, and make prerequisites and next
  steps easy to scan.
- Put human-facing directory concepts, workflows, and invariants in the nearest
  directory-level `README.md`.
- Do not duplicate exhaustive file descriptions or command references across
  README files.
- Unsuffixed Markdown files corresponding to commands under
  `scripts/k.commands/` are the user-facing help displayed by `k`.
  Update both language versions whenever command behavior, usage,
  prerequisites, or safety properties change.
- Use `AGENTS.md` for contributor instructions and README files for user
  documentation.

### Translations

- Publish human-facing Markdown in Korean at its unsuffixed path, such as
  `README.md` or `scripts/k.commands/apply.md`.
- Keep the canonical English source beside it with an `.en.md` suffix, such as
  `README.en.md` or `scripts/k.commands/apply.en.md`.
- Put reciprocal `한국어` and `English` links at the top of each translated pair
  and keep the pair structurally equivalent.
- Edit the English source first and update the Korean publication in the same
  change. Have a Korean speaker review safety-sensitive documentation.
- Keep commands, paths, identifiers, manifest fields, code blocks, URLs, and
  product names unchanged unless a localized value is part of the interface.
- Keep `AGENTS.md`, temporary notes under `working/`, and vendored documentation
  in English without translated copies.

## Repository contracts

- `state.yaml` is the authority for the cluster name, endpoint, nodes, and
  component versions.
  Keep versions as plain semantic versions without a `v` prefix.
- Every node declared in `state.yaml` requires `patches/<node>.yaml`.
  `patches/worker.yaml` and `patches/cilium.yaml` are shared by every node.
- Argo CD tracks this repository's `main` branch.
  Make desired-state changes in Git instead of editing Argo-managed resources in
  the cluster.
- A directory under `applications/` uses exactly one mode: managed `meta.yaml`
  plus `instances/`, or a custom `kustomization.yaml`.
  Do not mix the modes or use `kustomize.yaml` as the entrypoint.
- Every managed production, testing, and preview image must be digest-pinned,
  and every source revision must be a full commit identifier.
  Preview identity comes from its path under
  `instances/preview/<workload>/<pull-request>.yaml`.
- `k` is exclusively for platform engineers. Application developers interact
  through application files, documentation, and pull requests; do not make
  application workflows depend on access to `k`.
- A custom application may explicitly target only its generated application
  namespace. Treat platform review of merged Git changes as the authorization
  boundary because application developers have no cluster credentials.
- Preserve existing command and application interfaces unless the user
  explicitly requests an interface change.
- Shell command files under `scripts/k.commands/` are sourced by `scripts/k`.
  They rely on its functions and globals and are not standalone executables.
  Preserve the directory-based command dispatch and matching help document.

## Generated files

Do not edit this generated schema directly:

- `argocd/charts/application/values.schema.json`

Edit `argocd/charts/application/values.schema.source.json` or the pinned version
as appropriate, then run:

```bash
k render application-schemas
```

Use `k render application-schemas --check` to detect stale generated output.
The command downloads version-pinned upstream definitions and therefore needs
network access.

`.sops.yaml` is derived from `secrets/state.yaml` by the `k secrets recipients`
workflow.
Do not hand-edit it.

## Secrets and local credentials

- `secrets/state.yaml` contains public age recipients.
  Other files under `secrets/` are encrypted and must remain encrypted in Git.
- Never print, log, copy into documentation, or commit decrypted values.
- Do not run `k secrets edit`, recipient add/remove commands, or SOPS rekeying
  unless the user explicitly requests the corresponding secret change.
- `kubeconfig`, `talosconfig`, generated machine configuration, and local age
  keys are local credentials.
  They must remain untracked and must not be read or exposed without an explicit
  need.

## Operational safety

Do not run cluster-mutating operations unless the user explicitly asks for the
specific operation and target.
This includes:

- `k install`, `k initialize`, `k apply`, `k upgrade`, and `k reset`;
- mutating `kubectl`, `helm`, `talosctl`, or `cilium` commands;
- commands using `--yes` or otherwise bypassing confirmation.

`k apply` reconfigures every node declared in `state.yaml`. `k reset` wipes the
selected node's Talos `STATE` and `EPHEMERAL` partitions.
Never use a live cluster as a validation environment for an ordinary code or
documentation change.

## Validation

Run the smallest relevant local checks and report checks that could not be run.
The normal repository-wide checks are:

```bash
nix fmt -- --ci .
nix flake check
```

`nix flake check` checks formatting, shell quality, repository invariants,
representative Helm and Kustomize renders, version consistency, and Worker unit
tests. For schema changes, also run the schema generator's `--check` mode. For
Worker changes, also run `bun run check` and the Wrangler deployment dry-run.
For Argo CD, Kustomize, application metadata, or chart changes, render any
additional affected local configuration with the tools in the Nix development
shell; do not apply the rendered output to a cluster.

Generate and validate every targeted Talos machine configuration before applying
any of them. Generated names must remain unique and fit Kubernetes and DNS
limits. Keep durable architecture and operating procedures in the nearest
README; working notes must not be the only source for a lasting contract.
