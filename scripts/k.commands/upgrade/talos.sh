require_optional_yes "k upgrade talos [--yes]" "$@"

targets=()
for node in "${NODES[@]}"; do
  IFS=: read -r node_name node_ip <<<"$node"
  server_version="$(talosctl version --nodes "$node_ip" --short | awk '/^Server:/ { server = 1; next } server && /Tag:/ { print $2; exit }')"
  [[ -n $server_version ]] || {
    echo "Could not determine the Talos version on $node_name" >&2
    return 1
  }
  if [[ $server_version == "$TALOS_VERSION" ]]; then
    echo "$node_name already runs Talos $server_version"
  else
    targets+=("$node")
  fi
done
((${#targets[@]})) || return 0

confirm_action "k upgrade talos [--yes]" "Upgrade Talos to $TALOS_VERSION?" "$@"
for node in "${targets[@]}"; do
  node_ip="${node#*:}"
  talosctl upgrade --nodes "$node_ip" --image "$TALOS_INSTALL_IMAGE" --wait
done
run wait talos
