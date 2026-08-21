# E2S attachment rehearsal

Date: 2026-08-21

## Outcome

E2S was installed and joined successfully as the second Talos, etcd, and Kubernetes control-plane node. SCC remained available throughout the operation. E2S is currently cordoned because the Cilium cross-node pod datapath failed its connectivity rehearsal.

Current state:

- Talos nodes `k8s` and `e2s` are running and ready;
- both generated Talos configurations passed strict metal validation;
- etcd has two healthy non-learner members;
- Kubernetes nodes `k8s` and `e2s` are `Ready`;
- E2S has a ready 497 GB `EPHEMERAL` volume;
- E2S has a ready 1.9 TB `u-data` volume mounted at `/var/mnt/data`;
- Cilium and Envoy have one ready DaemonSet pod per node;
- the public Gateway and public DNS remain restricted to SCC;
- PXC remains one member on SCC;
- HAProxy remains one instance on SCC;
- Vault remains one member on SCC;
- Local Path Provisioner still excludes E2S; and
- Cilium operator remains at one replica pending datapath repair.

The remaining blocker is upstream network handling of Cilium VXLAN traffic toward SCC. PXC was deliberately not scaled while cross-node pod traffic was broken.

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

The expanded six-file topology was validated only in a detached temporary worktree. Its storage and PXC changes have not been applied because live Cilium cross-node testing found a network blocker.

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

The staged operation used four pushed commits:

- `0e4202c` labeled SCC for public Gateway listeners;
- `5502029` restricted Cilium host-network listeners to labeled nodes;
- `1a6862b` declared and configured E2S; and
- `edcf5f2` fixed `k wait talos` to verify every declared node directly.

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
1. E2S was cordoned after cross-node pod traffic failed.

No PXC, HAProxy, Vault, existing PVC, or existing PV configuration was changed.

## Cilium datapath blocker

The first Cilium connectivity test attempt was rejected by the cluster's Pod Security baseline because the upstream test workloads require `NET_RAW`, host ports, and host networking. Its temporary namespaces were removed. The test was rerun with only its temporary namespaces labeled privileged.

The privileged test scheduled workloads across both nodes but timed out on direct cross-node pod traffic. Follow-up checks found:

- both Cilium agents and both Envoy pods ready;
- each Cilium node had the expected pod CIDR;
- direct pod traffic from SCC to E2S failed;
- direct pod traffic from E2S to SCC failed;
- Cilium health reported only one of two endpoint networks reachable;
- host-level TCP health and etcd traffic remained reachable; and
- etcd remained healthy with two members.

A simultaneous packet capture established the asymmetric network boundary:

- SCC emitted UDP VXLAN packets to E2S destination port 8472;
- those packets arrived on E2S;
- E2S emitted UDP VXLAN replies toward SCC destination port 8472; and
- the replies did not arrive on SCC.

The likely missing rule is inbound UDP 8472 toward SCC from E2S. The network path should permit UDP 8472 in both directions between the SCC and E2S node addresses before the next test.

The failed test's temporary namespaces and resources were removed. E2S was cordoned without evicting or stopping its control-plane static pods or Cilium DaemonSets.

After the network rule is corrected:

1. rerun the privileged Cilium connectivity suite;
1. require two of two Cilium endpoint networks reachable;
1. verify cross-node DNS, ClusterIP, direct pod IP, and NodePort traffic;
1. uncordon E2S;
1. add E2S to Local Path Provisioner;
1. increase the Cilium operator to two replicas; and
1. continue with the two-member PXC and HAProxy rehearsal.

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

## Storage effect

The Talos `data` user volume can be created on E2S only after the old 1.9 TB partition table is removed. Once created, it should appear as `u-data`, be ready, and mount at `/var/mnt/data`.

The current `local-data` StorageClass remains intentionally restricted to Kubernetes node `k8s`. Its `nodePathMap` has no path for E2S. Therefore simply joining E2S does not permit local persistent-volume provisioning there.

After E2S is healthy, perform a separate GitOps change to:

1. add `e2s` to the StorageClass allowed topology;
1. add `e2s` with `/var/mnt/data` to `nodePathMap`;
1. reconcile Local Path Provisioner;
1. create a disposable storage test only with explicit authorization;
1. verify the resulting PV has E2S node affinity and resides under `/var/mnt/data`; and
1. remove the disposable test without touching retained production volumes.

Do not enable E2S in Local Path Provisioner before its Talos data volume and mount are verified.

## Database and Vault effect

Current state:

- PXC custom resource: ready;
- PXC members: 1 of 1 ready;
- HAProxy instances: 1 of 1 ready;
- PXC and HAProxy are explicitly selected to Kubernetes node `k8s`;
- PXC claim: retained 250 GiB `local-data` claim on SCC;
- Vault: 1 of 1 ready;
- Vault data and audit claims are retained on SCC;
- all three retained claims resolve to SCC-local paths under `/var/mnt/data`.

Attaching E2S does not move or replicate PXC or Vault. The existing selectors keep them on SCC, and the storage provisioner initially excludes E2S.

After E2S storage and Cilium pass their acceptance checks, the supervised PXC rehearsal may:

1. permit `local-data` on `e2s`;
1. remove the SCC-only PXC and HAProxy selectors;
1. retain required hostname anti-affinity;
1. set PXC size to two;
1. set HAProxy size to two;
1. retain both unsafe size flags;
1. retain `RollingUpdate`; and
1. verify SST, Galera Primary status, cluster size two, and one member and proxy per node.

Do not interpret this as HA. Either PXC member's loss can remove Galera quorum. Do not perform member-failure testing unless a database outage and recovery exercise are explicitly authorized.

Removing the SCC-only selectors changes both StatefulSet pod templates. Do not assume the operation only creates ordinal 1: the operator may also restart ordinal 0 and the existing HAProxy instance. Treat the transition as potentially disruptive, monitor the operator's update order, and take a fresh database backup first.

After E1S joins and all three data volumes are proven:

1. add E1S to local storage;
1. scale PXC and HAProxy from two to three;
1. restore `SmartUpdate`;
1. verify SST, Galera Primary status, cluster size three, and one member per node; and
1. remove unsafe size flags only after the three-member topology is healthy.

Vault scaling is a separate operation and requires its own Raft and recovery plan.

## Remaining execution sequence

1. Permit UDP 8472 in both directions between SCC and E2S, with particular attention to inbound traffic toward SCC.
1. Rerun the privileged Cilium connectivity test and clean up its temporary resources.
1. Require direct cross-node pod traffic and two of two Cilium endpoint networks to pass.
1. Uncordon E2S.
1. Add E2S to Local Path Provisioner in a reviewed GitOps change.
1. Prove E2S local provisioning before changing PXC.
1. Increase Cilium operator replicas to two.
1. Scale PXC and HAProxy to two with unsafe flags and `RollingUpdate` retained.
1. Verify one PXC member, HAProxy instance, and local PXC volume per node.
1. Verify SST, replicated writes, reads through HAProxy, and Galera status without simulating a node failure.
1. Optionally add the public Gateway label to E2S in a separate test after all internal networking passes.

## Acceptance status

Passed:

- E2S reports stage `running` and ready;
- hostname is `e2s`, domain is `k8s`;
- Talos member ID is unique;
- `u-data` is ready and mounted at `/var/mnt/data`;
- no Talos diagnostics are present;
- nodes `k8s` and `e2s` are both `Ready`;
- etcd shows exactly two healthy, non-learner members;
- control-plane static pods are ready on both nodes;
- two Cilium agents and two Envoy DaemonSet pods are ready;
- Gateway status and public DNS remain SCC-only;
- PXC remains one member on SCC and reports ready;
- HAProxy remains ready on SCC;
- Vault remains ready on SCC; and
- existing retained PVCs and PV node affinity are unchanged.

Blocked:

- Cilium cross-node endpoint health;
- direct cross-node pod traffic;
- enabling E2S in Local Path Provisioner;
- increasing Cilium operator replicas;
- uncordoning E2S; and
- the two-member PXC and HAProxy rehearsal.

Two-member PXC acceptance criteria remain:

- PXC pods are distributed one per node;
- each PXC claim binds to a PV on the same node as its member;
- both members report `Synced`, `Primary`, and ready;
- `wsrep_cluster_size` is two;
- HAProxy has one ready instance per node;
- writes through HAProxy replicate to both members;
- both unsafe size flags remain enabled;
- `RollingUpdate` remains configured; and
- Vault remains a single member on SCC.

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
