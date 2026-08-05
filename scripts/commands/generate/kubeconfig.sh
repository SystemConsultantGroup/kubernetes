require_no_args "t generate kubeconfig" "$@"

talosctl kubeconfig "$KUBECONFIG" --nodes "$MAIN_IP" --force --merge=false
chmod 600 "$KUBECONFIG"
