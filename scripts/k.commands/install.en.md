[한국어](install.md) | English

# install

Bootstraps the cluster through creation of the Argo CD GitOps root.

## Usage

```bash
k install
k install <command>
```

Running `k install` with no subcommand performs the complete bootstrap in this
order:

1. installs Talos configuration, Kubernetes, and etcd;
1. renders and applies Gateway API and Cilium bootstrap manifests;
1. waits for cluster networking; and
1. renders and applies Argo CD, bootstrap credentials, and the root Application.

The command stops at the GitOps boundary. The root Application reconciles
Cilium, Gateway API, Argo CD, other platform components, and application
workloads thereafter. Initialize fresh Vault storage separately with
`k initialize vault` after its platform Application is available.

## Subcommands

- `kubernetes` installs Talos configuration, Kubernetes, etcd, and local
  credentials.
- `cilium` bootstraps the CNI and Gateway API definitions before Argo CD can run.
- `argocd` bootstraps Argo CD, required Secrets, and the GitOps root.

## Prerequisites

For the full bootstrap:

- every encrypted Talos and bootstrap secret is decryptable and contains real
  values;
- every declared node has `patches/<node>.yaml`;
- `patches/worker.yaml` and `patches/cilium.yaml` exist; and
- the pinned Gateway API, Cilium, and Argo CD artifacts are reachable.

Before changing the cluster, the full command validates bootstrap values and all
Talos inputs. It stops at the first failure; individual steps can be rerun after
a partial failure. These are live cluster-changing operations and have no
confirmation prompt.
