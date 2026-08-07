# Excluded legacy repositories and components

Durable disposition of every legacy `*-config` repository (and in-repo component) that is
**not** ported into `working/applications/`. All config-repo links are pinned to the
2026-08-07 snapshot commit of that repository (from the snapshot git metadata). No secret or
credential values are recorded here — only names, mechanisms, and defects.

## Excluded platform / stateful / stale / superseded config repositories

| Legacy config repo (pinned commit) | Classification | Reason excluded / notable defects |
| --- | --- | --- |
| [`cloudflared-config@d22f351`](https://github.com/SystemConsultantGroup/cloudflared-config/tree/d22f35190c3c5a91e2b041e8a28113fc2695025f) | platform | Outbound Cloudflare tunnel (`cloudflare/cloudflared:latest`), 2 replicas, liveness `/ready:2000`, no Service/Ingress, no SCG source repo. Platform-owned; tunnel credentials live in a Secret. |
| [`codex-lb-config@aea6b04`](https://github.com/SystemConsultantGroup/codex-lb-config/tree/aea6b04006b0c4e304b4f3f0aa2e3aed1b5bf928) | third-party, stateful | `ghcr.io/soju06/codex-lb:1.22.0`, Recreate + 5Gi RWO PVC, writable `emptyDir`, custom command on port 2455, startup/readiness/liveness probes, dev-only host `dev.codex-lb.scg.sh` with source allowlist. No SCG repo; chart v1 cannot represent persistence, command, lifecycle, or probes. |
| [`cs-grad-thesis-config@9e27ac3`](https://github.com/SystemConsultantGroup/cs-grad-thesis-config/tree/9e27ac372a01746a9d60154452c8308b9ae69abf) | stale, non-fitting | Dormant since 2024-02-11; project repos (`cs-grad-thesis-frontend`/`-backend`, private) default to `develop`, have Dockerfiles but no GitHub workflows — images are pushed to internal `registry.scg.skku.ac.kr` outside GitHub. BE references external ConfigMap `cs-grad-thesis-prod-config` not defined in any fetched branch; NodePort Services. No trusted publisher or provenance. |
| [`SCG-Monitoring-Config@7482cc7`](https://github.com/SystemConsultantGroup/SCG-Monitoring-Config/tree/7482cc7dd43ad31c2926a8a9f605057b85e1a9d3) | platform, stateful | kube-prometheus-stack Helm chart with Grafana/Alertmanager PVCs, RBAC, CRDs. Defect: Argo values path references `values/value.yaml` while the tree contains `values/values.yaml` — fix before any sync. |
| [`office-config@aeed8ed`](https://github.com/SystemConsultantGroup/office-config/tree/aeed8ed38dfabd38c436ca527bdf1e0679aae86e) | platform placeholder | One-replica `nginx:alpine` LoadBalancer (10443) SSL stub for `office.scg.sh` serving a ConfigMap-mounted nginx config that returns 200; no backend or certificate material evidenced. Platform probe component or delete with owner approval; no registration. |
| [`renovate-config@b08a366`](https://github.com/SystemConsultantGroup/renovate-config/tree/b08a366f41334fe58c24171d0988997b53b04624) | platform tool | Tuesday CronJob running `renovate/renovate:latest` with Secret + ConfigMap; no HTTP Service. Cross-cutting dependency bot, not an application. |
| [`scg-new-2022-config@1cdd880`](https://github.com/SystemConsultantGroup/scg-new-2022-config/tree/1cdd880cce8976e1fbcef0f247dc080b9c7fea5b) | superseded | Homepage deployment superseded by `scg-home-config`; SCG-new-2022's workflow now publishes there. Base images `scg-be:1`/`scg-fe:1` are cluster-local with no GitHub publisher. Render defects: prod BE/FE patch targets (`be-ingress`/`fe-ingress`) do not match base resources (base renders). Project `frontend/Dockerfile` contained an inline GitLab credential — rotate and audit history (value omitted). Do not double-register the SCG homepage. |
| [`SCG-SSO-config@6a4faa6`](https://github.com/SystemConsultantGroup/SCG-SSO-config/tree/6a4faa679c7046230b31c5b274d04c2f44d400e7) | platform identity | Org Keycloak (`scgskku/scg-sso`, port 8080, host `sso.scg.skku.ac.kr`) with root redirect to `/realms/inhouse/account`; external MySQL and identity state are central. Defects: workflow has a typo'd Docker registry secret name; project Dockerfile pins `keycloak:latest` unpinned. No registration without explicit identity-provider ownership approval. |

## Excluded components inside otherwise-ordinary config repositories

| Config repo (pinned commit) | Component | Reason excluded |
| --- | --- | --- |
| [`skku-alumni-config@fa2a053`](https://github.com/SystemConsultantGroup/skku-alumni-config/tree/fa2a05383cd92bcfb89d675f075b6e2023d52a5b) | `alumni-redis` (base/redis) | `redis:7-alpine` with `emptyDir` and `--appendonly yes` — restart loses data. Stateful; chart v1 non-goal. Recorded, not registered. |
| [`timetable-planner-config@47b3bcc`](https://github.com/SystemConsultantGroup/timetable-planner-config/tree/47b3bcc7d8289fb27f487f9aed398bc37fc30a93) | `timetable-planner-redis` (base/redis) | `redis:7-alpine`, persistence disabled (`--appendonly no`), password-backed by `timetable-planner-redis-secret`. Stateful; chart v1 non-goal. Recorded, not registered. |
