# Legacy config repository port

This note tracks the move of the legacy `SystemConsultantGroup/*-config`
Kustomize repositories into `applications/`. The legacy repositories and the
legacy cluster are unchanged; each application owner retires its config
repository after cutover.

## Ported applications

Each application's README lists its sources, legacy routes, and required Vault
keys. Locks pin the image digest that the legacy tag resolved to on 2026-11-09.
The source commit comes from the image's `org.opencontainers.image.revision`
label, and every commit was confirmed to exist in the labelled repository.

| Application | Legacy repository | Instances |
| --- | --- | --- |
| [`attendance-checker`](../applications/attendance-checker/README.md) | `attendance-checker-prod-config`, `attendance-checker-config` | production, testing |
| [`cssys`](../applications/cssys/README.md) | `CSE-undergrad-gp-manage-v2-config` | production |
| [`exhibition`](../applications/exhibition/README.md) (`be`, `fe`) | `exhibition-config` | production |
| [`icc-grad-dissertation`](../applications/icc-grad-dissertation/README.md) | `ICC-grad-dissertation-manage-config` | production |
| [`icc-haedong-seminar-reservation`](../applications/icc-haedong-seminar-reservation/README.md) | `ICC-haedong-seminar-reservation-config` | production |
| [`icc-lecture-enrollment`](../applications/icc-lecture-enrollment/README.md) | `ICC-lecture-enrollment-config` | production |
| [`iccsys`](../applications/iccsys/README.md) | `iccsys-config` | production, testing |
| [`room-reservation`](../applications/room-reservation/README.md) | `room-reservation-config` | production |
| [`scg-apply`](../applications/scg-apply/README.md) | `scg-apply-config` | production |
| [`scg-sso`](../applications/scg-sso/README.md) | `SCG-SSO-config` | production |
| [`shortener`](../applications/shortener/README.md) | `shortener-config` | production |
| [`s-top`](../applications/s-top/README.md) | `S-TOP-config` | production |
| [`timetable-planner`](../applications/timetable-planner/README.md) and [`-storage`](../applications/timetable-planner-storage/README.md) | `timetable-planner-config` | production |

Legacy dev and QA overlays of `room-reservation`, `scg-apply`, `shortener`,
`S-TOP`, and `timetable-planner` were not ported as testing instances.

## Not ported

| Legacy repository | Reason |
| --- | --- |
| `codex-lb-config`, `prompt-battle-config` | Use PersistentVolumeClaims; excluded from this port |
| `scg-home-config` | `scgskku/scg-home-be-prod` is not publicly pullable |
| `cs-grad-thesis-config`, `ourlim-config`, `scg-new-2022-config` | Mutable tags on legacy in-cluster registries; no verifiable digest. `scg-home-config` supersedes `scg-new-2022-config` |
| `PDF-config` | Kafka worker without an HTTP route; the platform has no Kafka |
| `skku-alumni-config` | Already onboarded as `alumni` |
| `cloudflared-config`, `renovate-config`, `SCG-Monitoring-Config`, `office-config` | Not HTTP applications, already provided by the platform, or archived |

## Blockers before each application is healthy

1. **Non-root images.** The shared chart enforces `runAsNonRoot`. Only the
   `scg-sso` image declares a numeric non-root user. Every other image runs as
   root or as a named user (`spring`, `node`, `nextjs`, `appuser`), which
   kubelet cannot verify, so its Pods fail with `CreateContainerConfigError`.
   Each application repository must set a numeric `USER` in its Dockerfile and
   adopt the shared [delivery workflow](../.github/workflows/README.md), which
   then replaces the lock.
1. **Vault values.** No Vault paths exist yet. Populate each documented path
   with values pointing at services reachable from this cluster, not at the
   legacy cluster's in-cluster addresses. Keys such as `PORT` and `APP_PORT`
   must equal the workload's `http.port`.
1. **Data.** Database and object-storage access depends on the
   [database migration](DATABASE_MIGRATION_GUIDE.md) and on MinIO credentials
   scoped per application.
1. **Durable files.** No workload has a volume. Applications that write uploads
   to a local path must use object storage instead.

## Domain cutover

No ported workload declares a public domain, so merging creates only internal
Services. Cut over each application in its own pull request:

1. Add `http.domain` and any `http.rules` and filters that reproduce the legacy
   path routing, rewrites, CORS, and body-size settings in its README.
1. Choose the certificate issuer that can validate the zone.
1. Move DNS from the legacy ingress to the public Gateway.
1. Retire the legacy deployment and archive its config repository.
