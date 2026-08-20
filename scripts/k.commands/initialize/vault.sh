require_no_args "k initialize vault" "$@"
require_bootstrap_secrets
require_vault_secrets
require_vault_worker
require_file "$ROOT_DIR/argocd/platform/vault/policies/active.hcl"
require_file "$ROOT_DIR/argocd/platform/vault/policies/applications.hcl"
require_file "$ROOT_DIR/argocd/platform/vault/policies/platform.hcl"

configure_vault_policy() {
  local token="$1" name="$2" policy_file="$3"
  {
    printf '%s\n' "$token"
    cat "$policy_file"
  } | kubectl -n vault exec -i vault-0 -- /bin/sh -ec '
    IFS= read -r VAULT_TOKEN
    export VAULT_TOKEN VAULT_SKIP_VERIFY=true
    vault policy write "$1" - >/dev/null
  ' vault-policy "$name"
}

configure_vault_applications() {
  local token="$1"

  configure_vault_policy "$token" applications \
    "$ROOT_DIR/argocd/platform/vault/policies/applications.hcl"

  printf '%s\n' "$token" | kubectl -n vault exec -i vault-0 -- /bin/sh -ec '
    IFS= read -r VAULT_TOKEN
    export VAULT_TOKEN VAULT_SKIP_VERIFY=true
    vault write auth/kubernetes/role/applications \
      bound_service_account_names=vault-auth \
      bound_service_account_namespaces="*" \
      audience=vault \
      token_policies=applications \
      token_no_default_policy=true \
      token_ttl=1h \
      token_max_ttl=8h >/dev/null
  '
}

vault_token_valid() {
  local token="$1"
  printf '%s\n' "$token" | kubectl -n vault exec -i vault-0 -- /bin/sh -ec '
    IFS= read -r VAULT_TOKEN
    export VAULT_TOKEN VAULT_SKIP_VERIFY=true
    vault token lookup >/dev/null
  ' 2>/dev/null
}

configure_vault_oidc() {
  local token="$1" client_secret="$2"

  configure_vault_policy "$token" github-active \
    "$ROOT_DIR/argocd/platform/vault/policies/active.hcl"
  configure_vault_policy "$token" github-platform \
    "$ROOT_DIR/argocd/platform/vault/policies/platform.hcl"

  {
    printf '%s\n' "$token"
    printf '%s\n' "$client_secret"
  } | kubectl -n vault exec -i vault-0 -- /bin/sh -ec '
    IFS= read -r VAULT_TOKEN
    IFS= read -r oidc_client_secret
    export VAULT_TOKEN VAULT_SKIP_VERIFY=true

    vault auth list | grep -q '^oidc/' ||
      vault auth enable -path=oidc oidc >/dev/null
    vault auth tune \
      -listing-visibility=unauth \
      -description="GitHub via Argo CD Dex" \
      oidc/ >/dev/null

    printf %s "$oidc_client_secret" | vault write auth/oidc/config \
      oidc_discovery_url=https://argocd.platform.scg.sh/api/dex \
      oidc_client_id=vault \
      oidc_client_secret=- \
      default_role=github >/dev/null
    unset oidc_client_secret

    vault write auth/oidc/role/github \
      role_type=oidc \
      user_claim=sub \
      groups_claim=groups \
      oidc_scopes=openid,profile,email,groups \
      allowed_redirect_uris=http://localhost:8250/oidc/callback,https://vault.platform.scg.sh/ui/vault/auth/oidc/oidc/callback \
      token_ttl=1h \
      token_max_ttl=8h >/dev/null

    oidc_accessor="$(vault read -field=accessor sys/auth/oidc)"
    vault write identity/group/name/github-active \
      type=external policies=github-active >/dev/null
    vault write identity/group/name/github-platform \
      type=external policies=github-platform >/dev/null
    active_id="$(vault read -field=id identity/group/name/github-active)"
    platform_id="$(vault read -field=id identity/group/name/github-platform)"

    active_alias_group_id="$(vault write -field=id identity/lookup/group \
      alias_name=SystemConsultantGroup:active \
      alias_mount_accessor="$oidc_accessor" 2>/dev/null || true)"
    if [ -z "$active_alias_group_id" ]; then
      vault write identity/group-alias \
        name=SystemConsultantGroup:active \
        mount_accessor="$oidc_accessor" \
        canonical_id="$active_id" >/dev/null
    elif [ "$active_alias_group_id" != "$active_id" ]; then
      echo "Existing GitHub active alias targets the wrong Vault group" >&2
      exit 1
    fi

    platform_alias_group_id="$(vault write -field=id identity/lookup/group \
      alias_name=SystemConsultantGroup:platform \
      alias_mount_accessor="$oidc_accessor" 2>/dev/null || true)"
    if [ -z "$platform_alias_group_id" ]; then
      vault write identity/group-alias \
        name=SystemConsultantGroup:platform \
        mount_accessor="$oidc_accessor" \
        canonical_id="$platform_id" >/dev/null
    elif [ "$platform_alias_group_id" != "$platform_id" ]; then
      echo "Existing GitHub platform alias targets the wrong Vault group" >&2
      exit 1
    fi
  '
}

if ! curl --fail --silent --show-error \
  https://kms.vault.platform.scg.sh/healthz >/dev/null; then
  echo "Vault KMS Worker is unavailable; restore its secrets before installing Vault" >&2
  return 1
fi

vault_transit_seal_token="$(read_vault_secret VAULT_TRANSIT_SEAL_TOKEN)"
kubectl create namespace vault --dry-run=client -o yaml | kubectl apply -f -
printf '%s' "$vault_transit_seal_token" |
  kubectl -n vault create secret generic vault-transit-seal \
    --from-file=token=/dev/stdin --dry-run=client -o yaml | kubectl apply -f -
unset vault_transit_seal_token

work_dir="$(mktemp -d)"
status_file="$work_dir/status.json"
init_file="$work_dir/init.json"
encrypted_file="$work_dir/recovery.yaml"
preserve_init=0
cleanup_vault_install() {
  if ((preserve_init)); then
    chmod 600 "$init_file" 2>/dev/null || true
    rm -f "$status_file" "$encrypted_file"
    echo "Vault recovery encryption failed; plaintext recovery material remains at: $init_file" >&2
    echo "Secure it immediately, then remove $work_dir" >&2
  else
    rm -rf "$work_dir"
  fi
}
trap cleanup_vault_install EXIT

status_ready=0
for _ in $(seq 1 300); do
  if [[ $(kubectl -n vault get pod vault-0 -o jsonpath='{.status.phase}' 2>/dev/null || true) == Running ]]; then
    set +e
    kubectl -n vault exec vault-0 -- \
      vault status -tls-skip-verify -format=json >"$status_file" 2>/dev/null
    status=$?
    set -e
    if [[ $status -eq 0 || $status -eq 2 ]] && jq -e '.initialized | type == "boolean"' "$status_file" >/dev/null 2>&1; then
      status_ready=1
      break
    fi
  fi
  sleep 2
done
((status_ready)) || {
  echo "Timed out waiting for the Vault API" >&2
  return 1
}

if [[ $(jq -r '.initialized' "$status_file") == true ]]; then
  require_file "$VAULT_RECOVERY_FILE"
  sops decrypt "$VAULT_RECOVERY_FILE" >/dev/null
  root_token="$(sops decrypt --extract '["root_token"]' "$VAULT_RECOVERY_FILE" 2>/dev/null || true)"
  if [[ -n $root_token ]] && vault_token_valid "$root_token"; then
    oidc_client_secret="$(read_bootstrap_secret VAULT_OIDC_CLIENT_SECRET)"
    configure_vault_oidc "$root_token" "$oidc_client_secret"
    configure_vault_applications "$root_token"
    unset oidc_client_secret
    echo "Vault is already initialized; privileged configuration was reconciled"
  else
    echo "Vault is already initialized; no valid bootstrap root token was available for reconciliation"
  fi
  unset root_token
  echo "Existing recovery material was retained"
  return
fi

umask 077
kubectl -n vault exec vault-0 -- \
  vault operator init -tls-skip-verify -format=json \
  -recovery-shares=5 -recovery-threshold=3 >"$init_file"
preserve_init=1
jq -e '.root_token | length > 0' "$init_file" >/dev/null
jq -e '.recovery_keys_b64 | length == 5' "$init_file" >/dev/null

sops encrypt \
  --filename-override "${VAULT_RECOVERY_FILE#"$ROOT_DIR/"}" \
  --input-type json \
  --output-type yaml \
  "$init_file" >"$encrypted_file"
sops decrypt --input-type yaml --output-type json "$encrypted_file" |
  jq -e '(.root_token | length > 0) and (.recovery_keys_b64 | length == 5)' >/dev/null
mv "$encrypted_file" "$VAULT_RECOVERY_FILE"
chmod 644 "$VAULT_RECOVERY_FILE"
preserve_init=0

{
  jq -r '.root_token' "$init_file"
  printf '\n'
} | kubectl -n vault exec -i vault-0 -- /bin/sh -ec '
  IFS= read -r VAULT_TOKEN
  export VAULT_TOKEN VAULT_SKIP_VERIFY=true
  vault audit enable file file_path=/vault/audit/audit.log
  vault secrets enable -path=kv kv-v2
  vault auth enable kubernetes
  vault write auth/kubernetes/config \
    kubernetes_host=https://kubernetes.default.svc:443
'

root_token="$(jq -r '.root_token' "$init_file")"
oidc_client_secret="$(read_bootstrap_secret VAULT_OIDC_CLIENT_SECRET)"
configure_vault_oidc "$root_token" "$oidc_client_secret"
configure_vault_applications "$root_token"
unset root_token oidc_client_secret

public_ready=0
for _ in $(seq 1 60); do
  if curl --fail --silent --show-error \
    https://vault.platform.scg.sh/v1/sys/health >/dev/null 2>&1; then
    public_ready=1
    break
  fi
  sleep 2
done
((public_ready)) || {
  echo "Vault initialized, but its public health endpoint did not become ready" >&2
  return 1
}

echo "Vault initialized and recovery material written to secrets/vault-recovery.yaml"
echo "Commit the updated encrypted recovery file before considering the reset complete"
