# Alumni storage

Dedicated, internal-only Redis for the new alumni production deployment.
The application reuses an existing MinIO service and the existing alumni MySQL.
This application does not provision MinIO or change the legacy cluster.
Argo CD discovers this custom application as namespace `alumni-storage`.

## Before merging

Create these KV v2 secrets through the Vault UI (plain strings, no base64):

| Path under kv | Required keys |
| --- | --- |
| applications/alumni-storage/production/redis | REDIS_PASSWORD |

Use new strong random credentials. Do not reuse legacy or MySQL backup credentials.
Missing Secrets keep the containers from starting; no insecure defaults are used.
The custom application declares its own ExternalSecrets using the existing
`applications` Vault role. Credential changes trigger Reloader; coordinate Redis
password rotation with the backend to avoid an authentication outage.

## Services and data

- Redis: `redis.alumni-storage.svc.cluster.local:6379`

Redis is ClusterIP only. No Ingress, HTTPRoute, DNS, or public LoadBalancer
is created. ClusterIP does not isolate callers within the cluster; authentication
is required and in-cluster transport is plaintext.

Redis uses a 2 GiB `local-data` claim with AOF enabled
and a 256 MiB no-eviction memory limit. These are initial requested sizes, not
disk quotas. Redis has a single replica and node-local storage, so it
is not highly available. PVCs are retained on StatefulSet deletion or scale-down.
Do not delete claims during rollback. There is no backup for this new volume;
review recovery requirements before production use.

Pinned image: Redis 7.4.8-alpine.
Operators must review upstream security/support status before production use.

## Upload account

Use the existing MinIO service and bucket `skku-alumni-prod` with a dedicated
application user/policy with bucket existence/list and object read/write/delete
permissions scoped to this bucket. Pre-create the bucket so the application does
not require global bucket creation privileges. Keep the bucket private; the
backend serves uploaded images. Do not give the backend MinIO root credentials.
Store `MINIO_ENDPOINT` (the reachable S3 API URL), `MINIO_ACCESS_KEY`, and
`MINIO_SECRET_KEY` in `kv/applications/alumni/production/be`. No
`applications/alumni-storage/production/minio` Vault path is required.
Coordinate version retention, capacity, and independent backups with the MinIO
operator. Creating a new bucket does not migrate existing production uploads.

Application onboarding and the deferred DB credential gate are documented in
[the onboarding guide](../../onboarding/alumni/README.md).
