if (($#)); then
  run_group render "$@"
  return
fi

run render application-schemas
run render manifests
