require_no_args "k generate talosconfig" "$@"

talos_secrets="$(decrypt_talos_secrets)"
trap 'rm -f "$talos_secrets"' EXIT

talosctl gen config "$CLUSTER_NAME" "$CLUSTER_ENDPOINT" \
    --install-image "$TALOS_INSTALL_IMAGE" \
    --talos-version "$TALOS_VERSION" \
    --kubernetes-version "$KUBERNETES_VERSION" \
    --with-secrets "$talos_secrets" \
    --output-types talosconfig \
    --force
chmod 600 "$TALOSCONFIG"
talosctl config endpoints "$MAIN_IP" --talosconfig "$TALOSCONFIG"
