require_no_args "k ensure kubeconfig" "$@"

if [[ -f $KUBECONFIG ]] && kubectl --kubeconfig "$KUBECONFIG" --request-timeout=5s auth can-i get namespaces >/dev/null 2>&1; then
  chmod 600 "$KUBECONFIG"
  echo "kubeconfig is usable"
  return
fi

require_file "$TALOSCONFIG"
temporary_kubeconfig="$(mktemp)"
trap 'rm -f "$temporary_kubeconfig"' EXIT

talosctl kubeconfig "$temporary_kubeconfig" --nodes "$MAIN_IP" --force --merge=false
chmod 600 "$temporary_kubeconfig"
kubectl --kubeconfig "$temporary_kubeconfig" --request-timeout=10s auth can-i get namespaces >/dev/null
mv "$temporary_kubeconfig" "$KUBECONFIG"
echo "Ensured kubeconfig"
