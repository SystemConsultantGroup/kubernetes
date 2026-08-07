require_optional_yes "k upgrade talos [--yes]" "$@"

targets=()
for node in "${NODES[@]}"; do
    IFS=: read -r node_name node_ip <<<"$node"
    current="$(talosctl version --nodes "$node_ip" --short | awk '/Tag:/ { print $2; exit }')"
    if [[ "$current" == "$TALOS_VERSION" ]]; then
        echo "$node_name already runs Talos $current"
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
