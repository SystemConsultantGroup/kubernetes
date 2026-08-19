require_optional_yes "k configure vault-applications" "$@"

VAULT_ADDR="${VAULT_ADDR:-https://vault.platform.scg.sh}"
export VAULT_ADDR

managed_applications() {
  local directory application

  for directory in "$ROOT_DIR"/applications/*; do
    [[ -d $directory && -f $directory/meta.yaml && -d $directory/instances ]] || continue
    application="${directory##*/}"
    [[ $application =~ ^[a-z0-9]([-a-z0-9]*[a-z0-9])?$ ]] || {
      echo "Invalid managed application directory: ${directory#"$ROOT_DIR/"}" >&2
      return 1
    }
    printf '%s\n' "$application"
  done
}

write_policy() {
  local application="$1" instance_type="$2" role="$application-$instance_type"

  case "$instance_type" in
  production | testing)
    vault policy write "$role" - >/dev/null <<EOF
path "kv/data/applications/$application/$instance_type/*" {
  capabilities = ["read"]
}

path "auth/token/lookup-self" {
  capabilities = ["read"]
}
EOF
    ;;
  preview)
    vault policy write "$role" - >/dev/null <<EOF
path "kv/data/applications/$application/testing/*" {
  capabilities = ["read"]
}

path "kv/data/applications/$application/preview/*" {
  capabilities = ["read"]
}

path "auth/token/lookup-self" {
  capabilities = ["read"]
}
EOF
    ;;
  esac
}

write_role() {
  local application="$1" instance_type="$2" role="$application-$instance_type"

  if [[ $instance_type == preview ]]; then
    vault write "auth/kubernetes/role/$role" \
      bound_service_account_names=vault-auth \
      bound_service_account_namespace_selector="{\"matchLabels\":{\"platform.scg.sh/application\":\"$application\",\"platform.scg.sh/instance-type\":\"preview\"}}" \
      audience=vault \
      token_policies="$role" \
      token_no_default_policy=true \
      token_ttl=1h \
      token_max_ttl=8h >/dev/null
    return
  fi

  vault write "auth/kubernetes/role/$role" \
    bound_service_account_names=vault-auth \
    bound_service_account_namespaces="$application-$instance_type" \
    audience=vault \
    token_policies="$role" \
    token_no_default_policy=true \
    token_ttl=1h \
    token_max_ttl=8h >/dev/null
}

mapfile -t applications < <(managed_applications)
((${#applications[@]})) || {
  echo "No managed applications found" >&2
  exit 1
}

if ! vault token lookup >/dev/null; then
  echo "Log in with: vault login -method=oidc role=github" >&2
  exit 1
fi

confirm_action \
  "k configure vault-applications" \
  "Reconcile Vault policies and Kubernetes auth roles at $VAULT_ADDR?" \
  "$@"

for application in "${applications[@]}"; do
  for instance_type in production testing preview; do
    write_policy "$application" "$instance_type"
    write_role "$application" "$instance_type"
  done
done

echo "Vault application policies and Kubernetes auth roles reconciled"
