# Working notes

This directory contains temporary investigation, rollout, and migration notes.
It is not the authoritative location for lasting repository contracts.

When work is completed, move durable architecture decisions, invariants, and
operating procedures into the nearest component README. Keep only unresolved
observations and explicitly time-sensitive status here, and remove obsolete
transcripts rather than maintaining a second copy of component documentation.

`DATABASE.md` tracks the unfinished durable-storage and database design.
`VAULT.md` tracks Vault activation history and remaining operational work; the
supported component contract belongs under `argocd/platform/vault/`.
