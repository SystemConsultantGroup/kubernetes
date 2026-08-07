# PORTING notes: scg-home-be

Legacy evidence: [SystemConsultantGroup/scg-home-config@a33ebeb](https://github.com/SystemConsultantGroup/scg-home-config/tree/a33ebebc755a34d7dc286ec2210d3b2c0ee1713f)
(2026-08-07 snapshot). **No `meta.yaml`:** the legacy base serves `be.scg.skku.ac.kr/`, while the broken production overlay intends `scg.skku.ac.kr/api/v2`; current evidence does not establish the production contract.

## Candidate facts
- Repository `https://github.com/SystemConsultantGroup/SCG-new-2022.git` publishes `docker.io/scgskku/scg-home-be-prod`.
- Port 8000 and runtime literals `NODE_ENV=production`, `TZ=Asia/Seoul` are evidenced.
- TCP readiness is the safe default.

## Blockers
- Confirm the hostname/path from the frontend build configuration or live ownership decision before creating metadata.
- Implement CORS in the application or prove Gateway API `CORS` filter support; header modification alone does not reproduce nginx preflight behavior.
- Decide the school-domain TLS/DNS mode and whether Prometheus scraping needs a platform-owned mechanism.

## Unsupported legacy behavior
- nginx Ingress/TLS/CORS, Service scrape annotations, `imagePullPolicy: Always`, and broken overlay patches.
