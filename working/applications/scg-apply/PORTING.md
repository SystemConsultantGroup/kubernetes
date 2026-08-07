# scg-apply — PORTING notes

Paper port only; not operational. Legacy source: SystemConsultantGroup/scg-apply-config
@ 0872c32 (2026-08-07 snapshot). These notes record uncertainties and legacy behavior
the current platform (APPLICATION_PLATFORM.md) cannot represent. Nothing here invents
branches, domains, health paths, secrets, or runtime behavior.

## Uncertainties (must be resolved before migration)

1. DNS/TLS ownership of apply.scg.skku.ac.kr. Managed (external: false) was chosen from
   legacy cert-manager evidence, but the spec requires the hostname to belong to a
   configured ExternalDNS zone, and the sweep records that ExternalDNS currently filters
   to scg.sh. Confirm scg.skku.ac.kr zone support, or re-decide external: true only if the
   school firewall is proven to forward HTTP with Host preserved (contradicts legacy
   in-cluster TLS evidence).
2. Health semantics. No legacy probe exists; chart TCP readiness on 3000/8000 was chosen.
   Verify the containers actually listen and that TCP readiness is safe before rollout.
3. External dependencies. BE requires PostgreSQL (DATABASE_URL) and MinIO (MINIO_* keys in
   scg-apply-secret). Confirm those services remain reachable from namespace
   app-production-scg-apply (network policy / firewall) and that endpoint values are valid
   there. These are external services, not in-cluster state.
4. Frontend runtime env. The FE repo contains .env.production and a Next.js build; any
   NEXT_PUBLIC_*-style values are baked at image build time and must be supplied by the CI
   image-build contract, not chart runtime env.
5. Production branch. "main" is taken from both cd-prod.yaml triggers (push on main). No
   GitHub data for other branch publishing was available in this environment (source repos
   were not cloned; only tree listings + workflows were supplied).

## Unsupported legacy behavior (chart v1 cannot represent)

1. BE /v1 nginx proxy-body-size 200m annotation
   ([overlays/prod/be/ingress.yaml:8](https://github.com/SystemConsultantGroup/scg-apply-config/blob/0872c32185f370d921d5cf5d046a0fdde8438671/overlays/prod/be/ingress.yaml)) — upload limit is not expressible in generated or
   custom routes.
2. BE Service Prometheus scrape annotations ([overlays/prod/be/service.yaml:9-11](https://github.com/SystemConsultantGroup/scg-apply-config/blob/0872c32185f370d921d5cf5d046a0fdde8438671/overlays/prod/be/service.yaml),
   prometheus.io/scrape|port|path=/metrics); the backend does expose a /metrics Prometheus
   module (scg-apply-backend tree: src/metric/*). Scraping contract needs a platform
   capability (ServiceMonitor or annotation allowlist).
3. Dev overlay (overlays/dev/*): Harbor images registry.scg.skku.ac.kr/scg-apply-{frontend,
   backend}:dev0 with no verifiable GitHub publisher, ConfigMap env (scg-apply-dev-config;
   ConfigMaps are not a chart v1 feature), and a broken FE Service selector
   (deployment labels qa-fe vs Service selector fe). The dev overlay is therefore not a
   platform testing environment and does not justify a branches.testing value; testing is
   intentionally not declared (production-only application).
4. Build-time secrets: the BE workflow passes BUILD_DATABASE_URL as a Docker build-arg
   ([.github/workflows/cd-prod.yaml](https://github.com/SystemConsultantGroup/scg-apply-backend/blob/94e52bf28c06fda770c6a626be38bd2d3e6bc72c/.github/workflows/cd-prod.yaml)). Spec §7 forbids this; the build must switch to
   BuildKit secret mounts before migration.
5. Attestations: both workflows set provenance: false; the platform reusable workflow
   requires workflow-bound provenance/attestations. Legacy workflows also commit image-tag
   updates directly into scg-apply-config main via ACTION_TOKEN (Image Updater pattern);
   this is replaced by the central lock writer, and the legacy config repo becomes
   non-authoritative.
6. Legacy prod image "tags" are 40-hex commit SHAs used as tags, not digests; the lock
   workflow must publish and pin real digests before lock.yaml can exist.
7. Base Ingress host blabla.scg.skku.ac.kr is a placeholder ([base/fe/ingress.yaml](https://github.com/SystemConsultantGroup/scg-apply-config/blob/0872c32185f370d921d5cf5d046a0fdde8438671/base/fe/ingress.yaml),
   [base/be/ingress.yaml](https://github.com/SystemConsultantGroup/scg-apply-config/blob/0872c32185f370d921d5cf5d046a0fdde8438671/base/be/ingress.yaml)); all environments override it. Ignored.

## Secrets

- scg-apply-secret (BE only), same-namespace in app-production-scg-apply. Key names only:
  APP_ENV, APP_PORT, JWT_SECRET, DATABASE_URL, MINIO_END_POINT, MINIO_PORT,
  MINIO_ACCESS_KEY, MINIO_SECRET_KEY, MINIO_BUCKET_NAME
  ([overlays/prod/be/secret.yaml:7-15](https://github.com/SystemConsultantGroup/scg-apply-config/blob/0872c32185f370d921d5cf5d046a0fdde8438671/overlays/prod/be/secret.yaml), Vault AVP placeholders). Values must be provisioned
  by the selected external backend before rollout (spec §11).
