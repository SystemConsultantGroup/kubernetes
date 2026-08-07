# PORTING notes: cse-undergrad-gp-manage

Evidence basis: [SystemConsultantGroup/CSE-undergrad-gp-manage-v2-config@44fa5e4](https://github.com/SystemConsultantGroup/CSE-undergrad-gp-manage-v2-config/tree/44fa5e43af1dfc671a905b890fb9236c1a0ac605)
and [SystemConsultantGroup/CSE-undergrad-gp-manage-v2@2f7ea25](https://github.com/SystemConsultantGroup/CSE-undergrad-gp-manage-v2/tree/2f7ea25e90e671bb61d4a02a11c282bfb3018b01) (2026-08-07 snapshots).

## Unsupported legacy behavior (lost by design, confirmed by platform contract)
- `nginx.ingress.kubernetes.io/proxy-body-size: 2g` on both ingresses: no Gateway API or chart
  equivalent exists (generated routes carry no annotations; custom routes forbid them). The app
  uses multer uploads to MinIO, so this may cap or drop large uploads at the gateway default.
  Requires a platform decision (route capability matrix, gateway default limit) before cutover.
- `nginx.ingress.kubernetes.io/ssl-redirect: "false"` on the alias: covered by the external
  domain mode (HTTP-only listener, no redirect) once school-firewall behavior is validated.
- In-cluster cert-manager TLS on the primary host: the spec has no mode for "school-owned DNS
  already pointing at the cluster + in-cluster certificate" (see spec §5.3 and the domain-model
  gap in working/applications/README.md). Legacy `gitops-tls` Secret and nginx Ingress resources are not migrated.
- `imagePullPolicy: Always` and tag-pinned image ([`kustomization.yaml`](https://github.com/SystemConsultantGroup/CSE-undergrad-gp-manage-v2-config/blob/44fa5e43af1dfc671a905b890fb9236c1a0ac605/kustomization.yaml) `newTag` = full SHA):
  replaced by digest-pinned `IfNotPresent` under the lock contract.
- Legacy CD workflow directly edits and pushes the config repo: non-authoritative lock writes
  are forbidden; the caller workflow must replace it (see §7 of APPLICATION_PLATFORM.md).

## Uncertainties requiring verification before migration
- Managed vs external classification of the primary host `cssys.cs.skku.ac.kr` (BLOCKER; see the
  pinned config evidence above). `external: false` in the draft is the closest structural fit, not a verified
  fact.
- Whether SCG ExternalDNS can manage `cs.skku.ac.kr` / `skku.ac.kr` records at all, and whether
  the school firewall forwards HTTP (and/or TLS) to the cluster while preserving the Host header.
- Secret `PORT` value must equal 8091. The Secret's envFrom `PORT` overrides the Dockerfile
  `ENV PORT=8091`; a mismatch would break Service targeting. Verify the Vault value.
- Secret provisioning: `cse-undergrad-gp-manage-secret` (19 keys: SESSION_SECRET, PORT, DB_*,
  CSSYS_*, MINIO_*) must exist in every derived namespace before rollout. App hard-fails at
  startup without SESSION_SECRET (`app.js`) and will CrashLoopBackOff without a reachable MySQL.
- External MySQL and MinIO reachability from the derived namespace (hosts/ports come from the
  Secret; legacy deployed neither in-cluster).
- No HTTP readiness path exists: `/` 302-redirects to `/cssys` and is not a health endpoint.
  TCP readiness is used; do not claim an HTTP path.
- Digest of the currently deployed image (`docker.io/scgskku/cse-undergrad-gp-manage` at tag
  `2f7ea25e90e671bb61d4a02a11c282bfb3018b01` = current main HEAD) is unknown from this snapshot;
  resolve via registry `imagetools inspect` or the first attested build. Current CD publishes
  with `provenance: false`, so no attestation exists for the legacy image.

## Bootstrap
- First `lock.yaml` is created by the central lock writer from the first attested build of
  `main` (current HEAD `2f7ea25e90e671bb61d4a02a11c282bfb3018b01`), with sourceRevision equal to
  that commit. Until a lock snapshot exists, the chart cannot render this release; that is
  expected and not a metadata error.
