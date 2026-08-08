{
  description = "Kubernetes cluster tooling";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  outputs = { nixpkgs, ... }:
    let
      systems = [ "aarch64-darwin" "aarch64-linux" "x86_64-linux" ];
    in {
      devShells = nixpkgs.lib.genAttrs systems (system:
        let pkgs = nixpkgs.legacyPackages.${system};
        in {
          default = pkgs.mkShell {
            packages = with pkgs; [
              age
#              bashInteractive
              cilium-cli
              glow
              kubectl
              kubernetes-helm
              sops
              talosctl
              yq-go
            ];

            shellHook = ''
              export PATH="$PWD/scripts:$PATH"
              export TALOSCONFIG="$PWD/talosconfig"
              export KUBECONFIG="$PWD/kubeconfig"
              if [ -n "''${BASH_VERSION:-}" ]; then
                source "$PWD/scripts/k.completions"
              fi
            '';
          };
        });
    };
}
