# Alumni storage

Dedicated, internal-only MinIO and Redis for the new alumni deployment.
The legacy cluster, its MinIO, and the existing alumni MySQL are unchanged.
Argo CD discovers this custom application as namespace `alumni-storage`.

## Before merging

Create these KV v2 secrets through the Vault UI (plain strings, no base64):

| Path under kv | Required keys |
| --- | --- |
| applications/alumni-storage/production/minio | MINIO_ROOT_USER, MINIO_ROOT_PASSWORD |
| applications/alumni-storage/production/redis | REDIS_PASSWORD |

Use new strong random credentials. Do not reuse legacy or MySQL backup credentials.
Missing Secrets keep the containers from starting; no insecure defaults are used.
The custom application declares its own ExternalSecrets using the existing
`applications` Vault role. Credential changes trigger Reloader; coordinate Redis
password rotation with the backend to avoid an authentication outage.

## Services and data

- MinIO S3: `http://minio.alumni-storage.svc.cluster.local:9000`
- MinIO console: `minio.alumni-storage.svc.cluster.local:9001`
- Redis: `redis.alumni-storage.svc.cluster.local:6379`

Both services are ClusterIP only. No Ingress, HTTPRoute, DNS, or public LoadBalancer
is created. ClusterIP does not isolate callers within the cluster; authentication
is required and in-cluster transport is plaintext.

MinIO uses a 20 GiB `local-data` claim; Redis uses a 2 GiB claim with AOF enabled
and a 256 MiB no-eviction memory limit. These are initial requested sizes, not
disk quotas. Each service has a single replica and node-local storage, so neither
is highly available. PVCs are retained on StatefulSet deletion or scale-down.
Do not delete claims during rollback. There is no backup for these new volumes;
arrange an independent backup before storing real production uploads.

Pinned images: MinIO RELEASE.2025-09-07T16-13-09Z and Redis 7.4.8-alpine.
Operators must review upstream security/support status before production use.

## Upload account

After MinIO starts, an operator must create bucket `alumni` and a dedicated
application user/policy with bucket existence/list and object read/write/delete
permissions scoped to this bucket. Pre-create the bucket so the application does
not require global bucket creation privileges. Keep the bucket private; the
backend serves uploaded images. Do not give the backend MinIO root credentials.
Store the dedicated access key and secret key in
`kv/applications/alumni/production/be`.

Application onboarding and the deferred DB credential gate are documented in
[the onboarding guide](../../onboarding/alumni/README.md).
