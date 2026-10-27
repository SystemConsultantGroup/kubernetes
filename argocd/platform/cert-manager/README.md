# cert-manager

This component installs cert-manager and the certificates used by the public
Gateway. It uses the chart version pinned in [`../../../state.yaml`](../../../state.yaml)
and enables both CRD installation and Gateway API support.

## Issuance

The `zerossl-cloudflare` ClusterIssuer completes ZeroSSL ACME DNS-01 challenges
through Cloudflare. `k install argocd` creates these required Secrets before the
Application reconciles:

- `cert-manager/cloudflare-api-token`;
- `cert-manager/zerossl-eab`.

The manifests issue two Secrets in `gateway-system`:

| Secret | Names covered |
| --- | --- |
| `platform-wildcard-tls` | `*.platform.scg.sh` |
| `application-wildcards-tls` | `*.testing.scg.sh`, `*.preview.scg.sh` |

Managed production domains receive separate Certificates from the application
chart unless they are marked external.

## Alumni DNS-01 through Bindizr

`zerossl-bindizr` is a separate ClusterIssuer for exactly these names:

- `test.alumni.scg.skku.ac.kr`;
- `admin.test.alumni.scg.skku.ac.kr`;
- `api.test.alumni.scg.skku.ac.kr`.

It reuses the existing ZeroSSL account Secret `zerossl-cloudflare-account` with
account-key generation disabled. The existing Cloudflare issuer and wildcard
certificates are unchanged. Alumni workloads select it with
`http.certificateIssuer: zerossl-bindizr`.

DNS updates use TCP to `bindizr-dns.bindizr.svc.cluster.local:53`, the primary's
internal Service. The public BIND secondaries on port 53 do not accept updates.
Public DNS delegation and replication to the authoritative secondaries must
work before the CA can validate TXT records. cert-manager performs DNS zone
discovery and propagation checks through public DNS; the key does not need
`zone:transfer` access to the hidden primary.

### Before merging

A Bindizr administrator must create a dedicated role and TSIG key. Run these
once against the intended cluster; inspect existing names before retrying:

```bash
kubectl --context admin@scg exec -n bindizr deploy/bindizr -- \
  bindizr role create alumni-acme --description "Alumni cert-manager DNS-01"

for pattern in _acme-challenge.test.alumni _acme-challenge.admin.test.alumni _acme-challenge.api.test.alumni; do
  kubectl --context admin@scg exec -n bindizr deploy/bindizr -- \
    bindizr role grant alumni-acme --zone scg.skku.ac.kr \
    --actions record:read,record:create,record:delete --pattern "$pattern" --types TXT
done

kubectl --context admin@scg exec -n bindizr deploy/bindizr -- \
  bindizr tsig-key create alumni-acme --role alumni-acme --algorithm hmac-sha256
```

Patterns are exact record names relative to `scg.skku.ac.kr`, not wildcard
grants. Confirm the zone is not separately delegated below this level. The last
command displays a generated secret: transfer it directly to the Vault UI, not
Git, a PR, or chat. Do not use the example's zone-wide certbot transfer grant.

In Vault's `kv` engine, create `platform/cert-manager/bindizr` with key
`TSIG_SECRET`. Paste the generated base64 TSIG secret as the value exactly as
provided. Do not decode or base64-encode it again; External Secrets handles the
Kubernetes Secret encoding. The TSIG key name must be `alumni-acme`, and its
algorithm must be HMAC-SHA256 as declared in the issuer.

A Vault platform administrator must also apply the committed policy and role.
From this repository with Vault CLI available, authenticate through OIDC:

```bash
export VAULT_ADDR=https://vault.platform.scg.sh
vault login -method=oidc role=github
vault policy write cert-manager-dns argocd/platform/vault/policies/cert-manager-dns.hcl
vault write auth/kubernetes/role/cert-manager-dns \
  bound_service_account_names=cert-manager-dns-vault-auth \
  bound_service_account_namespaces=cert-manager \
  audience=vault token_policies=cert-manager-dns \
  token_no_default_policy=true token_ttl=1h token_max_ttl=8h
```

The initial root token has been revoked, so rerunning `k initialize vault` is
not a substitute for this explicit role/policy operation. The bootstrap script
includes the same setup for future fresh installations.

### Secret delivery and verification

The `cert-manager-dns` SecretStore authenticates with only the
`cert-manager/cert-manager-dns-vault-auth` ServiceAccount. Its Vault policy can
read only `kv/data/platform/cert-manager/bindizr`. The ExternalSecret creates
`cert-manager/bindizr-rfc2136` with key `tsig-secret` and refreshes every minute.
Neither the application workloads nor their namespace-wildcard Vault role can
read this platform path.

Merge after the key and Vault access are prepared. Argo CD reconciles the
SecretStore, ExternalSecret, issuer, and alumni Certificate issuer references;
no application image rebuild or DB operation is needed. Existing certificates
and TLS Secret names stay the same. Do not delete TLS Secrets to trigger renewal.

```bash
kubectl --context admin@scg get secretstore,externalsecret -n cert-manager
kubectl --context admin@scg get clusterissuer zerossl-bindizr
kubectl --context admin@scg get certificates,certificaterequests,orders,challenges -n alumni-production
kubectl --context admin@scg get application alumni-production -n argocd
```

Expect the ExternalSecret and certificates to become Ready, challenges to
complete, and the Application to become Healthy. If updates are refused, verify
the exact relative-name grants, algorithm, key name, and primary endpoint. If
records are presented but checks stay pending, inspect public NS delegation and
secondary replication. Adding a hostname later requires updating the issuer's
selector and granting that exact TXT name before requesting a certificate.

## Changes and diagnosis

Keep the chart pin synchronized with `cert-manager.version` in `state.yaml`.
Changing the issuer, ACME account, DNS provider, or wildcard names is a
platform-wide certificate migration. Verify the issuer before diagnosing a
Certificate, then its CertificateRequest, Order, and Challenge resources.
Never place the EAB HMAC key or Cloudflare token in these manifests or values.
