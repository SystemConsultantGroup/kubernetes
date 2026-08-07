# PORTING notes: pdf

Legacy evidence: [SystemConsultantGroup/PDF-config@8bd32a7](https://github.com/SystemConsultantGroup/PDF-config/tree/8bd32a713e794f0ad003baac0b152a0aa2e05f8f)
(2026-08-07 snapshot). Production-only; **internal Service with no routes**
(`domain`/`routes` omitted — spec §5.2 requires domain only when routes exists).
Stateless Kafka → Puppeteer → MinIO consumer.

## Assumptions
- `port: 4000` (`main.ts app.listen(4000)`); TCP readiness default — root `/` returns
  "Hello World!", no health endpoint.
- `image: docker.io/jcy0308/pdf-module` (Docker Hub personal namespace, verified from CD.yml
  login). Registry explicit, tagless.
- Legacy resources preserved: requests cpu 2 / memory 3Gi, limits cpu 2 / memory 4Gi.
- Legacy `dev` overlay is not a testing release; source repo has only `main`.

## Blockers
- **Env contract (P3):** `TOPIC`/`CONSUMER_GROUP`/`APP_ENV` come only from a `.env` baked into
  the image (ConfigModule skips `.env` when `APP_ENV=production`); the legacy Secret does not
  contain them and the chart has no ConfigMap support. Needs secret-side or source-side
  decision — do not invent literal values.
- Attestation: personal Docker Hub + `provenance: false`; lock writer needs attested rebuilds.
- `pdf-secret` (SASL/MinIO keys; note legacy `SASL_MACHANISM` typo is not read by the app —
  mechanism is hardcoded `scram-sha-256`) must be provisioned before rollout.
- Previews are effectively dead: preview namespaces deny cluster-network egress, so they cannot
  reach `kafka.kafka.svc.cluster.local:9092` or MinIO.
- Activity evidence is stale (config 2025-01-27, source HEAD 2024-09-02) — confirm the pipeline
  is still in production (P1).
