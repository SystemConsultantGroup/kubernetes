require_no_args "k install vault" "$@"
require_vault_secrets
require_file "$ROOT_DIR/argocd/platform/vault/application.yaml"

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

kubectl apply -f "$ROOT_DIR/argocd/platform/vault/application.yaml"

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
  echo "Vault is already initialized; existing recovery material was retained"
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
  jq -e '.root_token | length > 0 and (.recovery_keys_b64 | length == 5)' >/dev/null
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
    kubernetes_host=https://kubernetes.default.svc:443 \
    kubernetes_ca_cert=@/var/run/secrets/kubernetes.io/serviceaccount/ca.crt \
    token_reviewer_jwt=@/var/run/secrets/kubernetes.io/serviceaccount/token
'

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
