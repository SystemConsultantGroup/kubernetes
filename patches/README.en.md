[한국어](README.md) | English

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
The current state enables `scc` and `e2s`.

## Disk selectors

`machine.install.diskSelector.wwid` selects the system disk.
Verify the WWID on the target machine before installation or apply.
Replace placeholders such as `REPLACE_WITH_E1S_SYSTEM_DISK_WWID` before enabling
a node.

The `scc` and `e2s` patches also declare partition-based Talos user volumes
named `data` from their selected disks, mounted at `/var/mnt/data`. The selectors
use stable WWIDs and request growth into each disk's available space. Verify live
Talos volume and mount status before assigning workloads to either path.

Do not put credentials here.
Talos secrets remain in encrypted
[`../secrets/talos.yaml`](../secrets/talos.yaml).

## Applying changes

`k apply` regenerates and validates every configuration before applying any of
them to the nodes in `state.yaml`; it is a live operation with no dry-run mode.
Review the target nodes, disk selectors, and generated intent before running it.
Kubernetes installation uses the same patch set.
