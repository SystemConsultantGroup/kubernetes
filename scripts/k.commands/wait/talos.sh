require_no_args "k wait talos" "$@"

node_ips=()
deadline=$((SECONDS + 600))
echo "Waiting for direct Talos API access to every declared node..."
for node in "${NODES[@]}"; do
  IFS=: read -r node_name node_ip <<<"$node"
  node_ips+=("$node_ip")
  until talosctl version --endpoints "$node_ip" --nodes "$node_ip" >/dev/null 2>&1; do
    if ((SECONDS >= deadline)); then
      echo "Talos API on $node_name is not ready after 10 minutes" >&2
      return 1
    fi
    sleep 5
  done
  echo "$node_name Talos API is ready"
done

control_plane_nodes="$(
  IFS=,
  echo "${node_ips[*]}"
)"
echo "Waiting for Talos and Kubernetes health across declared control-plane nodes..."
echo "Transient health errors are expected while services start; the command keeps waiting unless the health check times out."
talosctl health --nodes "$MAIN_IP" --control-plane-nodes "$control_plane_nodes"
echo "Talos and Kubernetes are ready"
