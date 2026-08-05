require_no_args "t wait talos" "$@"

echo "Waiting for Talos and Kubernetes..."
for node in "${NODES[@]}"; do
    IFS=: read -r _ node_ip <<< "$node"
    talosctl health --nodes "$node_ip"
done
echo "Talos and Kubernetes are ready"
