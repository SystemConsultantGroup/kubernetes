require_no_args "k ensure talosconfig" "$@"

talos_secrets="$(decrypt_talos_secrets)"
temporary_talosconfig="$(mktemp)"
cleanup_talosconfig() {
  rm -f "$talos_secrets" "$temporary_talosconfig"
}
trap cleanup_talosconfig EXIT

talosctl gen config "$CLUSTER_NAME" "$CLUSTER_ENDPOINT" \
  --install-image "$TALOS_INSTALL_IMAGE" \
  --talos-version "$TALOS_VERSION" \
  --kubernetes-version "$KUBERNETES_VERSION" \
  --with-secrets "$talos_secrets" \
  --output-types talosconfig \
  --output "$temporary_talosconfig" \
  --force
talosctl config endpoints "$MAIN_IP" --talosconfig "$temporary_talosconfig"
chmod 600 "$temporary_talosconfig"

if [[ -f $TALOSCONFIG ]] && cmp -s "$temporary_talosconfig" "$TALOSCONFIG"; then
  chmod 600 "$TALOSCONFIG"
  echo "talosconfig is current"
else
  mv "$temporary_talosconfig" "$TALOSCONFIG"
  echo "Ensured talosconfig"
fi
