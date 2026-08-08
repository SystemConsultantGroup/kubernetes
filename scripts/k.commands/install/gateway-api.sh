require_no_args "k install gateway-api" "$@"

kubectl apply --server-side -f "https://github.com/kubernetes-sigs/gateway-api/releases/download/v$GATEWAY_API_VERSION/standard-install.yaml"
