# Local path provisioner

This platform component dynamically provisions node-local PersistentVolumes for
the `local-data` StorageClass. It uses Rancher's Local Path Provisioner pinned to
an immutable upstream commit.

The class is intentionally not the cluster default. Workloads must request it
explicitly:

```yaml
storageClassName: local-data
```

Volumes bind with `WaitForFirstConsumer`, so scheduling selects the node before
the local path is created. The class currently permits only Kubernetes node
`k8s` and stores data below the Talos user volume mounted at:

```text
/var/mnt/data
```

Unlisted nodes have no provisioning paths. Add a node only after its own durable
Talos user volume exists.

The reclaim policy is `Retain`. Deleting a claim does not erase its local data or
make its PersistentVolume automatically reusable. An operator must inspect and
clean retained data before deleting or replacing the PersistentVolume.

Local volumes are not replicated and cannot move to another node. Applications
must provide their own replication or accept node-local availability.
