# ourlim — PORTING notes (migration evidence; NOT chart input)

Source of truth: [SystemConsultantGroup/ourlim-config@442f108](https://github.com/SystemConsultantGroup/ourlim-config/tree/442f108ac94d574ad1174345f1446b3f611d9e9a)
(main, 2025-01-12; 2026-08-07 snapshot).
Platform spec: working/APPLICATION_PLATFORM.md.

**No `meta.yaml`:** the source-repository production branch was not captured, so a strict draft would have to invent required metadata.

## Candidate decisions
- One application `ourlim`; workloads `fe` + `be`; repository
  https://github.com/SystemConsultantGroup/ourlim.git reused by both (spec §5.2).
- Same-host FE `/` + BE `/api/v1` split via generated routes (§5.5). Legacy nginx path
  `/api/v1(/|$)(.*)` with pathType Prefix and NO rewrite-target annotation means the backend
  received the unchanged URI; Gateway API PathPrefix `/api/v1` (segment-boundary match)
  preserves that behavior. Verify conformance incl. `/api/v1xyz` non-match before sync.
- Production-only: no testing/QA overlay or branch evidence (config repo has only `main`).
- readiness: tcp on declared ports 3000/8000 — legacy has no probes; no HTTP health path claimed.
- domain.external: false (managed): cert-manager in-cluster TLS evidence; blocked until
  `scg.skku.ac.kr` is in the configured ExternalDNS zone allowlist.
- No lock.yaml until image publication is attested (Blocker 1).

## Evidence (file:line at the pinned config commit)
- [base/fe/deployment.yaml:9-12](https://github.com/SystemConsultantGroup/ourlim-config/blob/442f108ac94d574ad1174345f1446b3f611d9e9a/base/fe/deployment.yaml) — image harbor.k8s.scg.skku.ac.kr/library/ourlim-fe,
  containerPort 3000, replicas 1
- [base/be/deployment.yaml:9-12](https://github.com/SystemConsultantGroup/ourlim-config/blob/442f108ac94d574ad1174345f1446b3f611d9e9a/base/be/deployment.yaml) — image harbor.k8s.scg.skku.ac.kr/library/ourlim-be,
  containerPort 8000, replicas 1
- [base/fe/service.yaml](https://github.com/SystemConsultantGroup/ourlim-config/blob/442f108ac94d574ad1174345f1446b3f611d9e9a/base/fe/service.yaml), [base/be/service.yaml](https://github.com/SystemConsultantGroup/ourlim-config/blob/442f108ac94d574ad1174345f1446b3f611d9e9a/base/be/service.yaml) — NodePort 80->3000 / 80->8000
  (chart renders ClusterIP; NodePort was never exposed externally, only via Ingress)
- [base/fe/ingress.yaml:13-23](https://github.com/SystemConsultantGroup/ourlim-config/blob/442f108ac94d574ad1174345f1446b3f611d9e9a/base/fe/ingress.yaml), [base/be/ingress.yaml:13-23](https://github.com/SystemConsultantGroup/ourlim-config/blob/442f108ac94d574ad1174345f1446b3f611d9e9a/base/be/ingress.yaml) — placeholder host
  `blabla.scg.skku.ac.kr` (template artifact; not a real production host)
- [overlays/prod/fe/ingress.yaml](https://github.com/SystemConsultantGroup/ourlim-config/blob/442f108ac94d574ad1174345f1446b3f611d9e9a/overlays/prod/fe/ingress.yaml) — host ourlim.scg.skku.ac.kr, path `/` Prefix
- [overlays/prod/be/ingress.yaml](https://github.com/SystemConsultantGroup/ourlim-config/blob/442f108ac94d574ad1174345f1446b3f611d9e9a/overlays/prod/be/ingress.yaml) — host ourlim.scg.skku.ac.kr, path `/api/v1(/|$)(.*)` Prefix,
  no rewrite/redirect/CORS annotations
- [overlays/prod/fe/kustomization.yaml:13](https://github.com/SystemConsultantGroup/ourlim-config/blob/442f108ac94d574ad1174345f1446b3f611d9e9a/overlays/prod/fe/kustomization.yaml) — newTag prod2; [overlays/prod/be/kustomization.yaml:13](https://github.com/SystemConsultantGroup/ourlim-config/blob/442f108ac94d574ad1174345f1446b3f611d9e9a/overlays/prod/be/kustomization.yaml)
  — newTag prod1 (deployment evidence only; tags are not metadata)
- [overlays/prod/be/deployment.yaml:17-19](https://github.com/SystemConsultantGroup/ourlim-config/blob/442f108ac94d574ad1174345f1446b3f611d9e9a/overlays/prod/be/deployment.yaml) — envFrom secretRef ourlim-secret
- [overlays/prod/be/secret.yaml](https://github.com/SystemConsultantGroup/ourlim-config/blob/442f108ac94d574ad1174345f1446b3f611d9e9a/overlays/prod/be/secret.yaml) — key NAMES only: APP_ENV, DB_HOST, DB_PORT, DB_USERNAME,
  DB_PASSWORD, DB_NAME, APP_PORT, APP_BASE_URL, APP_DOMAIN, GOOGLE_CLIENT_ID, MINIO_END_POINT,
  MINIO_PORT, MINIO_ACCESS_KEY, MINIO_SECRET_KEY, MINIO_BUCKET_NAME; values are Vault
  placeholders (`kv/data/ourlim-secret`, some MINIO_* from `kv/data/minio`); values not
  reproduced here
- [SystemConsultantGroup/ourlim](https://github.com/SystemConsultantGroup/ourlim) — project repo (private): backend (NestJS) + frontend
  (Next.js) Dockerfiles; NO `.github/workflows/`; images pushed to internal Harbor outside
  GitHub Actions (unattested publish)
- Render check: `kubectl kustomize overlays/prod/fe` and `overlays/prod/be` both pass;
  rendered namespace `ourlim-prod`, names `prod-fe-*` / `prod-be-*`

## Uncertainties (resolve before migration)
1. Source-repo production branch: config repo `main` is evidenced; the production branch of
   SystemConsultantGroup/ourlim (private, no commit in this audit) is not. Confirm it before
   creating `meta.yaml`.
2. BE listener port: deployment declares 8000 but the secret env includes APP_PORT; confirm the
   NestJS listener actually binds 8000 in the prod image (TCP readiness on 8000 depends on it).
3. Domain/DNS: extend the ExternalDNS zone allowlist to `scg.skku.ac.kr`; validate the apex
   record and ListenerSet certificate; confirm `ourlim.scg.skku.ac.kr` is globally unique in
   the application registry.
4. Health: TCP readiness only; verify the app accepts TCP on 3000/8000 and needs no HTTP probe.
5. Gateway API equivalence: PathPrefix `/api/v1` vs legacy regex `/api/v1(/|$)(.*)`; verify
   precedence against FE `/` and segment-boundary behavior.
6. Secret provisioning: provision `ourlim-secret` in `app-production-ourlim` with the documented
   keys (incl. GOOGLE_CLIENT_ID, MINIO_*) before rollout; MinIO endpoint is an external,
   chart-non-goal dependency.
7. Preview: production-only app may preview from PRs targeting `main`, but previews require the
   trusted publish workflow (Blocker 1).

## Unsupported legacy behavior (not ported)
- NodePort Services -> chart ClusterIP (no external NodePort exposure existed)
- imagePullPolicy Always -> chart IfNotPresent (digest-pinned once lock.yaml exists)
- Vault AVP placeholders in Secret data -> external platform Secret provisioning (§11)
- shared TLS secret `gitops-tls` -> per-ListenerSet cert-manager material
- base placeholder host `blabla.scg.skku.ac.kr` -> dropped (never a production host)
