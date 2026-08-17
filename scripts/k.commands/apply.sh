require_no_args "k apply" "$@"
validate_talos_inputs

talos_secrets="$(decrypt_talos_secrets)"
machine_config=""
cleanup() {
  rm -f "$talos_secrets"
  [[ -z $machine_config ]] || rm -f "$machine_config"
}
trap cleanup EXIT

for node in "${NODES[@]}"; do
  IFS=: read -r node_name node_ip <<<"$node"
  machine_config="$(mktemp)"
  talosctl gen config "$CLUSTER_NAME" "$CLUSTER_ENDPOINT" \
    --install-image "$TALOS_INSTALL_IMAGE" \
    --talos-version "$TALOS_VERSION" \
    --kubernetes-version "$KUBERNETES_VERSION" \
    --with-secrets "$talos_secrets" \
    --config-patch "@$PATCH_DIR/$node_name.yaml" \
    --config-patch "@$PATCH_DIR/worker.yaml" \
    --config-patch "@$PATCH_DIR/cilium.yaml" \
    --output "$machine_config" \
    --output-types controlplane \
    --force
  if talosctl version --nodes "$node_ip" >/dev/null 2>&1; then
    talosctl apply-config --file "$machine_config" --nodes "$node_ip"
  else
    talosctl apply-config --file "$machine_config" --nodes "$node_ip" --insecure
  fi
  rm -f "$machine_config"
  machine_config=""
done
