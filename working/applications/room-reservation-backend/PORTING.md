# PORTING notes: room-reservation-backend

Legacy evidence: [SystemConsultantGroup/room-reservation-config@111b1e6](https://github.com/SystemConsultantGroup/room-reservation-config/tree/111b1e6b68243dd85817e9064aafc804da8314ae)
(2026-08-07 snapshot). Generated root route; legacy nginx CORS is not approximated with header modifiers.

## Assumptions
- `port: 8000` is supported by the Dockerfile and Service; TCP readiness default.
- `SPRING_PROFILES_ACTIVE` remains environment-scoped inside `reservation-secret`.
- Testing `develop` is intended to publish to the one canonical image repository through the replacement workflow.

## Blockers
- Implement CORS in the application or prove Gateway API `CORS` filter support in Cilium, including credentialed preflight behavior and environment-specific origins.
- The `scg.skku.ac.kr` TLS/DNS mode is unresolved.
- Provision `reservation-secret` in every available environment.

## Unsupported legacy behavior
- Legacy dev hosts, namespaces, nginx Ingress/TLS/CORS, and stale config-repository references in source workflows.
