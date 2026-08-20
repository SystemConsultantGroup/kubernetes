require_no_args "k install kubernetes" "$@"

run ensure talosconfig
run apply

if talosctl -n "$MAIN_IP" etcd members >/dev/null 2>&1; then
  echo "Etcd is already bootstrapped"
else
  echo "Bootstrapping etcd; transient connection errors are expected while Talos starts and are retried for up to 10 minutes."
  deadline=$((SECONDS + 600))
  until talosctl bootstrap --nodes "$MAIN_IP"; do
    if ((SECONDS >= deadline)); then
      echo "Timed out waiting to bootstrap etcd" >&2
      return 1
    fi
    sleep 10
  done
fi

run wait talos
run ensure kubeconfig
