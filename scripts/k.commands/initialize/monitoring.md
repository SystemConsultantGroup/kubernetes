# monitoring

Materializes Grafana's dedicated Dex client and stable chart administrator
secrets for an existing cluster.

## Usage

```bash
k initialize monitoring
```

The command reads `GRAFANA_OIDC_CLIENT_SECRET` and `GRAFANA_ADMIN_PASSWORD`
from encrypted `secrets/bootstrap.yaml`, creates the `argocd` and `monitoring`
namespaces when needed, and writes:

- the OIDC value to `argocd/argocd-grafana-oidc`, used by Argo CD's bundled
  Dex;
- the same OIDC value to `monitoring/grafana-oidc`, used by Grafana; and
- the administrator value to `monitoring/grafana-admin`, preventing Helm from
  generating a different password on every render.

The value moves only through standard input and is never written to command
arguments or plaintext files. Running the command again reconciles both Secrets.
Rotation also requires a separately authorized restart of the Argo CD Dex and
Grafana Deployments; this command does not restart workloads.

This is a live operation with no confirmation prompt. For the initial monitoring
rollout, run it from the reviewed revision before Argo CD reconciles the Dex
client and Grafana resources. Ordinary monitoring configuration changes do not
require rerunning it.

## Prerequisites

- `secrets/bootstrap.yaml` is decryptable and contains distinct,
  non-placeholder `GRAFANA_OIDC_CLIENT_SECRET` and `GRAFANA_ADMIN_PASSWORD`
  values.
- The cluster is reachable through the repository kubeconfig.
