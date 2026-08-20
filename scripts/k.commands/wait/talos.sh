require_no_args "k wait talos" "$@"

echo "Waiting for Talos and Kubernetes..."
echo "Transient health errors are expected while services start; the command keeps waiting unless the health check times out."
for node in "${NODES[@]}"; do
  IFS=: read -r _ node_ip <<<"$node"
  talosctl health --nodes "$node_ip"
done
echo "Talos and Kubernetes are ready"
