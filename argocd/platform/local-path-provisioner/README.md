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
`k8s` and stores data on its ready Talos `data` user volume at:

```text
/var/mnt/data
```

Unlisted nodes have no provisioning paths. SCC's retained Vault claims were
migrated from the previous `EPHEMERAL` path before this provisioning path
changed. Add another node only after its intended user volume, mount, and
durability are verified.

The reclaim policy is `Retain`. Deleting a claim does not erase its local data or
make its PersistentVolume automatically reusable. An operator must inspect and
clean retained data before deleting or replacing the PersistentVolume.

Local volumes are not replicated and cannot move to another node. Resetting
Talos `STATE` and `EPHEMERAL` does not erase the separately declared user
volume, but loss or erasure of its data RAID still destroys the volumes.
Applications must provide their own replication or off-cluster backups and
accept node-local availability.
