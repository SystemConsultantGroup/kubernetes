# E2S attachment rehearsal

Date: 2026-08-28

## Outcome

E2S was installed and joined successfully as the second Talos, etcd, and
Kubernetes control-plane node. The repaired Cilium VXLAN path passed the focused
cross-node acceptance suite, E2S local storage was proven, and the supervised
two-member PXC and HAProxy rehearsal completed successfully. SCC remained
available throughout the operation.

Current state:

- Talos nodes `k8s` and `e2s` are running, ready, and schedulable;
- etcd has two healthy, consistent, non-learner control-plane members;
- E2S has a ready 497 GB `EPHEMERAL` volume and a ready 1.9 TB `u-data` volume
  mounted at `/var/mnt/data`;
- Cilium and Envoy have one ready DaemonSet pod per node;
- Cilium has two ready operator replicas, one per node;
- `local-data` permits `k8s` and `e2s`, both at `/var/mnt/data`;
- the public Gateway status remains restricted to SCC;
- PXC has two ready, `Primary`, `Synced` members, one per node;
- HAProxy has two ready instances, one per node;
- each PXC member has a retained local PV with affinity to its own node; and
- Vault remains one member on SCC.

ICMP echo from E2S to SCC remains blocked. It is optional Cilium health
telemetry and is not a datapath or database blocker because TCP health, VXLAN,
pod IP, ClusterIP, DNS readiness, NodePort, SST/IST, and Galera traffic passed.

## Agreed E2S identity and storage

The rehearsal used:

- Talos hostname: `e2s.k8s`;
- Kubernetes node name: `e2s`;
- system disk: 500 GB logical drive with WWID `naa.61418770621bbc00321ac43f2b9a04af`;
- data disk: 1.9 TB logical drive with WWID `naa.61418770621bbc00321acff30706c889`;
- Talos user volume: `data`, mounted at `/var/mnt/data` after provisioning.

The hostname is intentionally location-first. Talos separates `e2s.k8s` into short hostname `e2s` and domain `k8s`, avoiding the existing SCC node's short identity `k8s`.

## E2S state

E2S is reachable at its declared address and is running Talos in maintenance mode.

Observed state:

- machine stage: `maintenance`;
- machine ready: `true`;
- Talos version: `1.13.7`;
- Talos schematic: `fd096f676a0df013f9631767d26696f8cb5ba7b7d3921cd8781a061a7ce9016d`;
- schematic and version match `state.yaml` exactly;
- machine type: `unknown`, as expected before applying cluster configuration;
- no installed Talos `META` or `STATE` volume;
- no mounted persistent volumes;
- network address, default route, DNS connectivity, and time synchronization are present;
- active network link: `eno1`;
- Talos API port 50000 is reachable from the operator host.

Hardware inventory:

- Dell PowerEdge R730;
- two Intel Xeon E5-2640 v3 processors;
- 16 physical cores and 32 hardware threads total;
- 96 GiB memory;
- PERC H730 Mini presenting two writable logical drives.

Talos reports no runtime diagnostics. This does not establish physical-disk, RAID degradation, cache battery, or media health; those require controller or BMC inspection.

## Existing E2S disk contents

Both logical drives contain old partition tables and data signatures.

The 500 GB system candidate currently contains:

- a 629 MB EFI partition;
- a 1.1 GB XFS partition; and
- a 498 GB LVM physical-volume partition.

The 1.9 TB data candidate currently contains:

- a 210 MB EFI partition;
- a 1.1 GB XFS partition; and
- a 1.9 TB partition with the Linux LVM partition type.

The system installation will erase the selected 500 GB drive. The `UserVolumeConfig` will not automatically repurpose the fully partitioned 1.9 TB drive because it requires enough unallocated space for `minSize: 1TB`. The data drive therefore needs a separate, explicitly authorized wipe before Talos can provision `u-data`.

No disk was wiped during this rehearsal.

## Proposed desired-state change

The tested hypothetical change enables E2S in `state.yaml` and changes `patches/e2s.yaml` to the following intent:

```yaml
apiVersion: v1alpha1
kind: HostnameConfig
hostname: e2s.k8s
auto: off
---
machine:
  install:
    diskSelector:
      wwid: naa.61418770621bbc00321ac43f2b9a04af
---
apiVersion: v1alpha1
kind: UserVolumeConfig
name: data
provisioning:
  diskSelector:
    match: disk.wwid == "naa.61418770621bbc00321acff30706c889"
  minSize: 1TB
  grow: true
```

The state change is:

```yaml
nodes:
  scc:
    address: "115.145.134.232"
  e2s:
    address: "115.145.172.19"
```

These changes were first tested in temporary files and a detached worktree, then committed to `main` and applied to the live E2S node.

## Offline validation

A complete E2S control-plane machine configuration was generated using the cluster's existing Talos secrets and these pins:

- Talos `1.13.7`;
- Kubernetes `1.36.3`;
- the repository's pinned factory schematic;
- control-plane endpoint on SCC;
- shared worker scheduling patch;
- CNI disabled in Talos;
- kube-proxy disabled for Cilium replacement.

Results:

- `talosctl validate --mode metal --strict`: passed;
- `nix fmt -- --ci .` against the hypothetical change: passed;
- `nix flake check` against the hypothetical change: passed;
- temporary generated configuration and decrypted secret material were removed;
- the real repository remained unchanged during validation.

## Expanded multi-node rehearsal

A second hypothetical worktree tested the complete two-node platform transition. It added these staged changes:

- label only SCC as an initial public Gateway listener node;
- restrict Cilium Gateway host-network listeners to that label;
- increase Cilium operator replicas from one to two;
- permit `local-data` provisioning on `k8s` and `e2s`;
- add `/var/mnt/data` to the E2S Local Path Provisioner map;
- increase PXC from one to two members;
- increase HAProxy from one to two instances; and
- remove the SCC-only selectors from PXC and HAProxy while retaining required hostname anti-affinity.

Validation results:

- strict Talos metal validation passed for both SCC and E2S;
- the Cilium chart rendered two operator replicas with required hostname anti-affinity;
- the Cilium Gateway node selector rendered as `gateway.scg.sh/listener=true`;
- the pinned Local Path Provisioner chart rendered allowed nodes `k8s,e2s`, `WaitForFirstConsumer`, and `Retain`;
- the PXC custom resource rendered two PXC members and two HAProxy instances without node selectors;
- both PXC unsafe size flags remained enabled;
- `RollingUpdate` remained enabled for the rehearsal;
- all local manifests rendered successfully;
- `nix fmt -- --ci .` passed; and
- `nix flake check` passed.

The expanded topology was first validated in a detached temporary worktree. Its
Gateway safety changes were applied before E2S joined. After the Cilium network
rule was repaired and the focused datapath suite passed, commits `35af2fb` and
`8a71162` applied the storage, operator, PXC, and HAProxy stages.

## Multi-node component decisions

### Cilium and Gateway

Cilium agent and Envoy are DaemonSets, so they automatically gain one pod on E2S. Their replica counts must not be set manually.

The Cilium operator should increase from one to two replicas after E2S joins. The chart already renders required hostname anti-affinity, so the two replicas distribute across the two nodes. Two operator replicas remain sufficient for the later three-node cluster.

The public Gateway requires a safety change before E2S joins. Host-network Gateway listeners currently select every Cilium node, and Cilium publishes selected node addresses in Gateway status. ExternalDNS uses that status and currently publishes every observed public hostname only to SCC. Without a selector, adding E2S may expose port 443 on E2S and add its address to public DNS before cross-node networking is validated.

The rehearsed safe sequence is:

1. label SCC `gateway.scg.sh/listener=true`;
1. configure `gatewayAPI.hostNetwork.nodes.matchLabels` to require that label;
1. attach and validate E2S without public listeners;
1. test Cilium, PXC, and ordinary cross-node services; and
1. add the Gateway label to E2S only as a separate public-ingress test.

### CoreDNS

CoreDNS already has two replicas and preferred hostname anti-affinity. Both currently run on SCC because it is the only node. No replica change is required. After E2S joins, a controlled rollout can verify that the scheduler places one replica on each node.

### Argo CD

All Argo CD components currently run as single replicas. No Argo CD replica change is required for node attachment or the PXC test. Scaling the application controller, Redis, repository server, or Dex introduces separate HA and sharding decisions and would not make a two-member etcd cluster highly available.

Keep Argo CD at its current sizes for this rehearsal. Resolve or accept its existing healthy `OutOfSync` baseline before attachment.

### Vault

Keep Vault at one Raft member on SCC. Do not scale Vault to two: two Raft members require both members for quorum and would add two new retained local claims. Vault should scale directly to three only after all three nodes have proven storage, snapshots, recovery material, and an explicit Raft join procedure.

### Other controllers

Keep cert-manager, External Secrets, ExternalDNS, Local Path Provisioner, Percona Operator, and Reloader at one replica for the two-node rehearsal. They are reconcilers rather than the data-plane test target, and their desired state can recover them after pod loss. Scaling their webhooks and leaders is a later availability improvement, not an attachment prerequisite.

Keep ordinary application replica counts unchanged. Use Cilium connectivity tests and the two HAProxy instances to prove cross-node service routing rather than changing unrelated workloads.

### Control-plane endpoint

The canonical Kubernetes control-plane endpoint remains SCC's address. This is sufficient to join E2S while SCC is healthy, but it is not a final highly available endpoint. Before treating the later three-control-plane topology as highly available, provide a health-checked external TCP load balancer or another stable endpoint that is not tied to SCC. A shared layer-two virtual IP is not assumed across these routed networks.

## Pre-attachment cluster baseline

Before attachment, the live cluster had one Kubernetes node and one etcd member.

Talos and Kubernetes:

- Kubernetes node `k8s` is `Ready`;
- Kubernetes version is `1.36.3`;
- Talos version is `1.13.7`;
- Talos health checks pass;
- etcd is healthy with one member and no reported errors;
- all observed pods are running and ready.

Cilium:

- Cilium agent: healthy;
- Cilium operator: healthy;
- Envoy DaemonSet: healthy;
- 25 of 25 cluster pods are managed by Cilium;
- Cilium and Envoy each currently have one ready DaemonSet pod.

Argo CD:

- the root Application and all platform Applications except `argocd` report `Synced` and `Healthy`;
- the `argocd` Application reports `OutOfSync` but `Healthy`;
- observed drift includes two HTTPRoutes and Redis secret-init RBAC resources.

The Argo CD drift is not caused by E2S, but resolving or explicitly accepting it before attachment would provide a cleaner operational baseline.

## Network gate

Both SCC and E2S have working default routes and are reachable from the operator host. The SCC Kubernetes API, Talos API, etcd ports, and Cilium health port are reachable from that host. E2S exposes only its maintenance Talos API before installation, as expected.

These observations do not prove that SCC and E2S can communicate directly across their separate routed networks. Before attachment, verify bidirectional policy and routing for:

- Talos API traffic;
- Kubernetes API traffic;
- etcd peer and client traffic; and
- the Cilium inter-node datapath and health traffic, including its VXLAN traffic.

After attachment, Cilium health and a cross-node connectivity test are mandatory before permitting ordinary workloads to depend on E2S.

## Live execution

The staged operation used these pushed commits:

- `0e4202c` labeled SCC for public Gateway listeners;
- `5502029` restricted Cilium host-network listeners to labeled nodes;
- `1a6862b` declared and configured E2S;
- `edcf5f2` fixed `k wait talos` to verify every declared node directly;
- `35af2fb` enabled E2S local storage and the second Cilium operator; and
- `8a71162` scaled PXC and HAProxy across SCC and E2S.

Execution sequence and results:

1. SCC received `gateway.scg.sh/listener=true` through Talos without rebooting.
1. Argo CD reconciled the Cilium listener selector.
1. Gateway status and all checked public DNS records remained SCC-only.
1. E2S maintenance state and both WWIDs were rechecked.
1. Only the E2S 1.9 TB data logical drive was explicitly wiped.
1. `k apply` regenerated and validated both machine configurations.
1. SCC accepted its unchanged configuration without rebooting.
1. E2S installed Talos to its 500 GB logical drive and rebooted.
1. E2S joined Talos discovery, etcd, and Kubernetes as `e2s`.
1. Talos health passed with both declared addresses supplied explicitly.
1. E2S `u-data` provisioned and mounted successfully.
1. Cilium and Envoy became ready on both nodes.
1. E2S was cordoned after the initial cross-node pod traffic test failed.
1. Bidirectional UDP 8472 was repaired and focused Cilium acceptance passed 24
   pod IP, ClusterIP, local NodePort, and remote NodePort actions.
1. E2S was uncordoned after the network and Talos storage gates passed.
1. A disposable claim proved E2S local provisioning, write/read behavior, node
   affinity, and cleanup under `/var/mnt/data`.
1. Cilium operator scaled to two ready replicas, one per node.
1. PXC and HAProxy scaled to two and distributed one instance per node.
1. XtraBackup SST initialized `mysql-pxc-1`; IST synchronized the restarted
   `mysql-pxc-0`; both returned `Primary`, `Synced`, and ready.
1. A write through HAProxy replicated to both members and the disposable test
   schema was removed from both.

Vault and its existing retained PVCs were not changed. The SCC PXC volume and
node affinity were preserved; one new retained PXC volume was provisioned on
E2S.

## Cilium datapath resolution

The first privileged test exposed asymmetric VXLAN handling: SCC-to-E2S UDP
8472 arrived, while E2S-to-SCC replies did not. After the upstream rule was
corrected, cross-node PXC port probes and Cilium endpoint HTTP checks worked in
both directions.

A focused Cilium CLI run then selected only:

- `no-policies/pod-to-pod`;
- `no-policies/pod-to-service`;
- `no-policies-extra/pod-to-remote-nodeport`; and
- `no-policies-extra/pod-to-local-nodeport`.

It completed 24 actions with no failures. Setup also proved DNS reachability to
both echo pods and access to the Kubernetes ClusterIP. This functionally
validated bidirectional VXLAN UDP 8472 across both pod CIDRs. Every temporary
Cilium namespace and resource was removed afterward.

The broader upstream suite still reports E2S-to-SCC ICMP echo failure and
external `1.1.1.1` timeouts. Those checks are not required for the internal
cluster acceptance boundary. TCP 4240 health works, and Cilium documents ICMP
echo as optional when HTTP health is available.

## Kubernetes and etcd effect

Applying the E2S control-plane configuration should cause Talos to:

1. install to the selected 500 GB system drive;
1. reboot into the installed Talos system;
1. authenticate with the existing cluster secrets;
1. join the existing etcd cluster;
1. register Kubernetes node `e2s`;
1. run a Cilium and Envoy DaemonSet pod; and
1. allow scheduling on the control-plane node.

A two-member etcd cluster has a quorum of two. Losing either SCC or E2S makes etcd unavailable. This is a transitional topology, not a high-availability improvement. It should be kept as short as practical before E1S becomes the third control-plane member.

Do not run `talosctl bootstrap` for E2S. The cluster is already bootstrapped, and new control-plane nodes join through the existing control-plane endpoint.

## Storage result

E2S `u-data` is ready and mounted as XFS at `/var/mnt/data`. Commit `35af2fb`
added `e2s` to the `local-data` allowed topology and node path map only after
that mount and the Cilium datapath were verified.

A disposable 1 GiB PVC forced to E2S bound to a PV with:

- node affinity `e2s`;
- host path under `/var/mnt/data`; and
- successful synchronized write and read behavior.

The test PV alone was changed to `Delete` for cleanup. Its namespace, claim, PV,
and exact host path were removed, while every retained production PV remained
unchanged. The real `local-data` StorageClass continues to use `Retain`.

The provisioner had accumulated intermittent false readiness failures from the
upstream one-second HTTP timeout despite zero restarts and successful create and
delete operations. The GitOps values now allow five seconds for readiness while
retaining the upstream liveness behavior.

## Database and Vault result

Before scaling, PXC reported `Primary`, `Synced`, `wsrep_ready=ON`, and cluster
size one. It contained zero application schemas and zero application base
tables. No Percona backup storage is configured, so no physical backup was
possible; proceeding was limited to this empty, disposable rehearsal state.

Commit `8a71162` removed the SCC-only PXC and HAProxy selectors, retained
required hostname anti-affinity, set both sizes to two, and retained both unsafe
size flags and `RollingUpdate`. Results:

- `mysql-pxc-0` and `mysql-haproxy-0` run on `k8s`;
- `mysql-pxc-1` and `mysql-haproxy-1` run on `e2s`;
- both 250 GiB PXC claims are bound to retained `local-data` PVs with matching
  node affinity and `/var/mnt/data` paths;
- XtraBackup SST initialized `mysql-pxc-1` from `mysql-pxc-0`;
- IST synchronized `mysql-pxc-0` after its supervised template restart;
- both members report `Primary`, `Synced`, connected, ready, and cluster size
  two;
- writes through the HAProxy service replicated to both members;
- the HAProxy replicas service returned reads from both Galera members; and
- the disposable replication schema was removed from both members.

Do not interpret this as HA. Both PXC members are required for Galera quorum.
Do not perform member-failure testing or an unsupervised rollout. Vault remains
one member on SCC and was not changed.

After E1S joins and all three data volumes are proven:

1. add E1S to local storage;
1. scale PXC and HAProxy from two to three;
1. restore `SmartUpdate`;
1. verify SST, Galera Primary status, cluster size three, and one member per node; and
1. remove unsafe size flags only after the three-member topology is healthy.

Vault scaling is a separate operation and requires its own Raft and recovery plan.

## Remaining execution sequence

The E2S attachment, storage proof, and two-member database rehearsal are
complete. Follow-up work is separate:

1. keep both nodes available until E1S can provide a third quorum member;
1. configure and prove approved PXC backup, restore, PITR, and offsite storage
   before production cutover;
1. add E1S only after repeating the Talos, Cilium, and local-storage gates;
1. scale PXC and HAProxy from two to three, restore `SmartUpdate`, and remove the
   unsafe size flags only after three-member health is proven; and
1. optionally test E2S as a public Gateway listener in a separate reviewed
   operation.

## Acceptance status

Passed:

- both Talos APIs and the complete Talos/Kubernetes health check pass;
- nodes `k8s` and `e2s` are `Ready` and schedulable;
- etcd has exactly two healthy, consistent control-plane members;
- E2S `u-data` is ready and mounted at `/var/mnt/data`;
- the focused Cilium suite passed all 24 internal actions;
- Cilium, Envoy, and two Cilium operators are ready across both nodes;
- E2S local provisioning, affinity, write/read, and cleanup passed;
- PXC and HAProxy are distributed one instance per node;
- XtraBackup SST and the subsequent IST completed;
- both PXC members report `Primary`, `Synced`, ready, and cluster size two;
- HAProxy writes replicated to both members and replica reads reached both;
- both unsafe size flags and `RollingUpdate` remain configured;
- the Gateway status remains SCC-only;
- Vault remains a single member on SCC;
- Argo CD reports Cilium, Local Path Provisioner, and MySQL `Synced/Healthy`;
  and
- a final five-minute window held every target ready with no new warning events.

Accepted exceptions and future blockers:

- E2S-to-SCC ICMP echo is optional and remains blocked;
- two-member etcd and PXC topologies are transitional, not highly available;
- PXC backup, restore, PITR, and offsite replication remain production-cutover
  blockers; and
- no node-failure rehearsal is authorized for the two-member database.

## Rollback boundary

Before disk wiping, rollback is simply to stop and leave E2S in maintenance mode.

After the data-disk wipe, old E2S data is no longer recoverable from that logical drive.

After applying the machine configuration, rollback may require removing a partially joined control-plane or etcd member and resetting E2S. Those are live and potentially destructive operations requiring a separate diagnosis and explicit authorization. Do not improvise member removal while etcd quorum is uncertain.

## References

Repository contracts and procedures:

- `state.yaml`
- `patches/README.md`
- `scripts/k.commands/apply.md`
- `scripts/k.commands/wait/talos.md`
- `scripts/k.commands/wait/kubernetes.md`
- `argocd/platform/cilium/README.md`
- `argocd/platform/local-path-provisioner/README.md`
- `argocd/platform/mysql/README.md`
- `argocd/platform/vault/README.md`
- `working/DATABASE_MIGRATION_GUIDE.md`

Cilium documentation:

- <https://docs.cilium.io/en/v1.20/network/servicemesh/gateway-api/gateway-api/>

Talos documentation:

- <https://docs.siderolabs.com/talos/v1.13/networking/configuration/hostname>
- <https://docs.siderolabs.com/talos/v1.13/configure-your-talos-cluster/storage-and-disk-management/disk-management/common>
- <https://docs.siderolabs.com/talos/v1.13/learn-more/control-plane>
