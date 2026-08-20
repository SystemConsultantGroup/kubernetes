# Talos machine patches

This directory contains the Talos configuration fragments used for every node.
The `k` commands combine the selected node patch with the shared worker and
Cilium patches before generating a control-plane machine configuration.

## Files

| File | Scope |
| --- | --- |
| `worker.yaml` | Shared worker settings, including scheduling workloads on control-plane nodes |
| `cilium.yaml` | Shared Cilium prerequisites: no Talos CNI and no kube-proxy |
| `<node>.yaml` | Node-specific hostname, disk selectors, and user volumes |

The node-specific files present are `scc.yaml`, `e1s.yaml`, and `e2s.yaml`.
Every node listed in [`../state.yaml`](../state.yaml) needs a matching file;
commented-out nodes are ignored until enabled.
The current state enables only `scc`.

## Disk selectors

`machine.install.diskSelector.wwid` selects the system disk.
Verify the WWID on the target machine before installation or apply.
Replace placeholders such as `REPLACE_WITH_E1S_SYSTEM_DISK_WWID` before enabling
a node.

The testing `scc` patch also declares a default partition-based Talos user
volume named `data` from the selected disk, with an intended mount at
`/var/mnt/data`. The selector uses a stable WWN symlink and requests growth into
the disk's available space. The declaration does not prove that the live volume
is ready; verify Talos volume status before assigning workloads to that path.

Do not put credentials here.
Talos secrets remain in encrypted
[`../secrets/talos.yaml`](../secrets/talos.yaml).

## Applying changes

`k apply` regenerates and validates every configuration before applying any of
them to the nodes in `state.yaml`; it is a live operation with no dry-run mode.
Review the target nodes, disk selectors, and generated intent before running it.
Kubernetes installation uses the same patch set.
