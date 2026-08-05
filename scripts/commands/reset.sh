force=0
requested=""
for argument in "$@"; do
    case "$argument" in
        --yes) force=1 ;;
        -*|'') echo "Usage: t reset [--yes] [node]" >&2; return 2 ;;
        *)
            [[ -z "$requested" ]] || { echo "Usage: t reset [--yes] [node]" >&2; return 2; }
            requested="$argument"
            ;;
    esac
done

node="$(resolve_node "${requested:-$MAIN_IP}")"
if [[ "$node" == -* || "$node" == *[[:space:]]* ]]; then
    echo "Invalid node: $node" >&2
    return 2
fi

if ((!force)); then
    printf 'Reset %s? This wipes STATE and EPHEMERAL data [y/N] ' "${requested:-$node}"
    if ! read -r answer || [[ ! "$answer" =~ ^[Yy]([Ee][Ss])?$ ]]; then
        echo "Reset cancelled"
        return 1
    fi
fi

talosctl -n "$node" reset \
    --graceful=false \
    --system-labels-to-wipe STATE \
    --system-labels-to-wipe EPHEMERAL \
    --reboot
