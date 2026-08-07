# PORTING notes: scg-home-fe

Legacy evidence: [SystemConsultantGroup/scg-home-config@a33ebeb](https://github.com/SystemConsultantGroup/scg-home-config/tree/a33ebebc755a34d7dc286ec2210d3b2c0ee1713f)
(2026-08-07 snapshot). Production-only custom route.

## Assumptions
- Port 3000, `NODE_ENV=production`, and TCP readiness follow the legacy Deployment.
- `scg.skku.ac.kr` retains managed HTTPS intent (`external: false`); registration waits for the school's DNS/TLS decision.
- The normal frontend route is available in every release.
- A separate production-only HTTPRoute redirects `/seminar` to exactly `https://seminar.scg.skku.ac.kr/` with status 308, matching nginx without leaking the production redirect into testing or previews.

## Blockers
- Prove custom-route injection plus Cilium `RequestRedirect` support.
- Decide the school-domain DNS/TLS mode.
- Confirm cross-application redirect ownership and live behavior.

## Unsupported legacy behavior
- `imagePullPolicy: Always`, NodePort drift, and the broken duplicate production Ingress overlay.
