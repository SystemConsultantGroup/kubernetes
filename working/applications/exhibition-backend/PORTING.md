# PORTING notes: exhibition-backend

Legacy evidence: [SystemConsultantGroup/exhibition-config@a0b7ead](https://github.com/SystemConsultantGroup/exhibition-config/tree/a0b7ead72f7e2a777d7d2b9474ce4e3b669d8cf0)
(2026-08-07 snapshot). Production-only (`branches.production: main`). `routes: custom` with one constrained HTTPRoute.

## Assumptions
- `port: 8080` over the stale Deployment `containerPort: 8000` (Service targetPort + Dockerfile
  EXPOSE agree on 8080).
- nginx `/v1/(.*)` rewrite `/$1` → HTTPRoute `PathPrefix /v1/` + `URLRewrite ReplacePrefixMatch /`.
  Gateway `PathPrefix` also accepts bare `/v1`; this is an intentional draft divergence that needs traffic validation.
- Legacy `enable-cors` annotation dropped safely: CORS is enforced app-side
  (`SecurityConfig`/`ExhibitionDomainCacheService`); the nginx annotation is redundant.
  Confirm the tenant-domain cache contains the FE origins at runtime.
- `exhibition-be-secret` provisioned externally per spec §11 (legacy Vault paths are `-dev`
  flavored even in the prod overlay — confirm production paths).

## Blockers
- **Custom-route path unimplemented:** §5.6/§13.11 Kustomize-injection + resource-allowlist
  proof must land before this route can sync.
- Gateway API schema + Cilium conformance for the rewrite filter must pass (§5.6).
- No `lock.yaml` (digests unavailable).

## Unsupported legacy behavior (not ported)
- nginx Ingress, cert-manager TLS, CORS annotation, `imagePullPolicy: Always`.

## Spec gap surfaced
- The school-domain TLS/DNS decision remains unresolved; this `scg.sh` route itself uses managed mode.
