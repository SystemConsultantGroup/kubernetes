# Working notes

This directory contains temporary investigation, rollout, and migration notes.
It is not the authoritative location for lasting repository contracts.

When work is completed, move durable architecture decisions, invariants, and
operating procedures into the nearest component README. Keep only unresolved
observations and explicitly time-sensitive status here, and remove obsolete
transcripts rather than maintaining a second copy of component documentation.

`DATABASE.md` tracks the unfinished storage and database migration plan, with a
current-plan summary before its decision transcript. `VAULT.md` now contains
only activation status, migration follow-up, and links to the durable component
contracts under `argocd/platform/vault/`, `argocd/charts/application/`, and
`workers/kms/`.
