# PORTING notes: timetable-planner-backend

Legacy evidence: [SystemConsultantGroup/timetable-planner-config@47b3bcc](https://github.com/SystemConsultantGroup/timetable-planner-config/tree/47b3bcc7d8289fb27f487f9aed398bc37fc30a93)
(2026-08-07 snapshot). Testing + production (`branches.testing: dev`, `branches.production: main`).

## Assumptions
- `port: 8080` (containerPort + Service 80→8080 — consistent, no conflict to resolve).
- `api.skkedule.scg.skku.ac.kr`, `external: false`.
- `timetable-planner-be-secret` (DB URL/credentials, Google OAuth, `REDIS_HOST`/`REDIS_PORT`/
  `REDIS_PASSWORD`) provisioned per derived namespace; `REDIS_HOST` must be re-pointed at the
  provisioned Redis dependency.
- No legacy CORS annotations; the FE also has a Next.js server-side proxy
  (`src/app/api/v1/[...slug]/route.ts`) — determine the actual browser→API path before
  inventing any CORS config.

## Blockers
- `scg.skku.ac.kr` zone not operational; cert issuance path for it unverified (Cloudflare-DNS01
  ClusterIssuer vs rfc2136 example).
- **Redis excluded (chart v1 non-goal)** and required by BE env — provisioning decision
  outstanding. Legacy Redis uses emptyDir + `--appendonly no` (data loss on restart).
- Source workflows `provenance: false` + direct config-repo pushes.

## Legacy defect (do not copy)
- The legacy BE Secret YAML contains a **duplicate `MCP_OAUTH` key** (prod and dev) — the
  strict parser (§5/§10) would reject it; the provisioner defines canonical keys.
