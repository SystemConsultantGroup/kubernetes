require_no_args "k apply" "$@"
validate_talos_inputs

talos_secrets="$(decrypt_talos_secrets)"
generated_directory="$(mktemp -d)"
cleanup() {
  rm -f "$talos_secrets"
  rm -rf "$generated_directory"
}
trap cleanup EXIT

for node in "${NODES[@]}"; do
  IFS=: read -r node_name node_address <<<"$node"
  machine_configuration="$generated_directory/$node_name.yaml"
  talosctl gen config "$CLUSTER_NAME" "$CLUSTER_ENDPOINT" \
    --install-image "$TALOS_INSTALL_IMAGE" \
    --talos-version "$TALOS_VERSION" \
    --kubernetes-version "$KUBERNETES_VERSION" \
    --with-secrets "$talos_secrets" \
    --config-patch "@$PATCH_DIR/$node_name.yaml" \
    --config-patch "@$PATCH_DIR/worker.yaml" \
    --config-patch "@$PATCH_DIR/cilium.yaml" \
    --output "$machine_configuration" \
    --output-types controlplane \
    --force
  talosctl validate --config "$machine_configuration" --mode metal --strict
  chmod 600 "$machine_configuration"
done

for node in "${NODES[@]}"; do
  IFS=: read -r node_name node_address <<<"$node"
  machine_configuration="$generated_directory/$node_name.yaml"
  if talosctl version --nodes "$node_address" >/dev/null 2>&1; then
    talosctl apply-config --file "$machine_configuration" --nodes "$node_address"
  elif talosctl get machinestatus --nodes "$node_address" --insecure >/dev/null 2>&1; then
    talosctl apply-config --file "$machine_configuration" --nodes "$node_address" --insecure
  else
    echo "Cannot authenticate to $node_name and it is not in maintenance mode" >&2
    return 1
  fi
done
