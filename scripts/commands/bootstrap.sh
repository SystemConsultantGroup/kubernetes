require_no_args "t bootstrap" "$@"

if talosctl -n "$MAIN_IP" etcd members >/dev/null 2>&1; then
    echo "Etcd is already bootstrapped"
    return
fi

deadline=$((SECONDS + 600))
until talosctl bootstrap --nodes "$MAIN_IP"; do
    if ((SECONDS >= deadline)); then
        echo "Timed out waiting to bootstrap etcd" >&2
        return 1
    fi
    sleep 10
done
