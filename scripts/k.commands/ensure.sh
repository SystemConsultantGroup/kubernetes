if (($#)); then
  run_group ensure "$@"
  return
fi

run ensure talosconfig
run ensure kubeconfig
