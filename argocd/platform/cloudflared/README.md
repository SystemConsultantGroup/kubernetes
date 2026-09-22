# Cloudflare Tunnel connector

This component runs the remotely managed `kubernetes` Cloudflare Tunnel inside
the cluster. Cloudflare routes the private hostname
`*.mysql.svc.cluster.local` to this tunnel; there are no public hostname or
private CIDR routes associated with it.

Two unprivileged replicas are spread across Kubernetes nodes. Each connector
uses cluster DNS to resolve the selected MySQL Service and can reach its
ClusterIP regardless of which node hosts the backend. The deployment therefore
does not need host networking, a TUN device, or the privileges required by a
Cloudflare Mesh connector.

## Tunnel credential

The tunnel token is a bootstrap credential, not GitOps desired state. It must
exist as key `token` in `cloudflared/cloudflared-tunnel-token`. The token is not
stored in this repository. `k install argocd` retrieves it from Cloudflare using
the encrypted bootstrap API token and the account and tunnel identifiers in
`state.yaml`, then creates or updates the Kubernetes Secret before installing
the Argo CD root Application.

The Deployment remains unavailable when the Secret is absent. Re-run
`k install argocd` only as part of the documented bootstrap or recovery workflow;
do not commit or print the tunnel token.

## Cloudflare configuration

The remotely managed tunnel configuration and hostname route live in the
Cloudflare account. The WARP device profile must send `cluster.local` DNS queries
to Gateway rather than Local Domain Fallback. Changes to the hostname route or
its identity and port policies are Cloudflare-side changes and are not reconciled
by Argo CD.
