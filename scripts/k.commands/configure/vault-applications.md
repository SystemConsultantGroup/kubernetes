# vault-applications

Reconciles scoped Vault policies and Kubernetes-auth roles for managed
applications.

## Usage

```bash
export VAULT_ADDR=https://vault.platform.scg.sh
vault login -method=oidc role=github
k configure vault-applications
```

Add `--yes` only for an intentional non-interactive reconciliation.

## Behavior

The command discovers directories using the managed `meta.yaml` plus
`instances/` layout. For each application, it writes these policies and roles:

- `<application>-production`, bound to `<application>-production`;
- `<application>-testing`, bound to `<application>-testing`; and
- `<application>-preview`, bound to namespaces labelled with the application
  and `platform.scg.sh/instance-type: preview`.

The policies allow only the KV v2 data paths documented in
[`../../../working/VAULT.md`](../../../working/VAULT.md) plus the required
`auth/token/lookup-self` provider validation endpoint. Preview policies can
also read testing paths for the approved fallback. Roles bind only the
`vault-auth` ServiceAccount, request the `vault` audience, and issue one-hour
tokens with an eight-hour maximum TTL.

The command is idempotent. It does not delete policies or roles for applications
removed from Git; remove those deliberately after decommissioning the
application.

## Prerequisites

- Vault is healthy at `https://vault.platform.scg.sh`.
- The caller is a `SystemConsultantGroup:platform` member and has authenticated
  with the GitHub OIDC role.
- The Vault Kubernetes auth method and its namespace-reader RBAC are already
  configured.

This is a live Vault operation. It changes access policies and authentication
roles, but does not write application secret values.
