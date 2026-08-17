# Talos machine patches

This directory contains the Talos machine configuration fragments used to
configure every cluster node. The `k` commands combine the selected node patch
with the shared worker and Cilium patches before applying the result.

## Files

| File | Scope |
| --- | --- |
| `worker.yaml` | Shared worker behavior, including scheduling workloads on control-plane nodes |
| `cilium.yaml` | Shared Cilium prerequisites: no Talos CNI and no kube-proxy |
| `<node>.yaml` | Node-specific disk selector and hostname configuration |

The current node-specific files are `scc.yaml`, `e1s.yaml`, and `e2s.yaml`.
Every node enabled in [`../state.yaml`](../state.yaml) must have a matching
file. Nodes still commented out in `state.yaml` are not configured by the
commands.

## Disk selectors

The `machine.install.diskSelector.wwid` value chooses the system disk. Verify
that the WWID is correct for the target machine before installing or applying a
patch. Placeholder values such as `REPLACE_WITH_E1S_SYSTEM_DISK_WWID` must be
replaced before enabling that node.

Do not put credentials in these files. Talos secrets are kept in the encrypted
[`../secrets/talos.yaml`](../secrets/talos.yaml).

## Applying changes

`k apply` regenerates and applies a machine configuration for every node in
`state.yaml`. It is a live, cluster-changing operation, not a dry run. Review
the generated intent and target node list before asking an operator to run it.
The same patches are used during Kubernetes installation.
