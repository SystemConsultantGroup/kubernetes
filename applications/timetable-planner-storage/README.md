# timetable-planner-storage

The Redis cache for [`timetable-planner`](../timetable-planner/README.md). Like
the legacy deployment, it disables persistence and evicts least-recently-used
keys at 128 MiB. Restarting the Pod clears the cache; no PersistentVolumeClaim
is created.

The backend connects to `redis.timetable-planner-storage.svc.cluster.local:6379`.

## Vault values

Path: `kv/applications/timetable-planner-storage/production/redis`.

Key: `REDIS_PASSWORD`. It must match the backend's `REDIS_PASSWORD`. Redis
refuses to start while the value is missing or empty.
