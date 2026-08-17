{
  description = "Kubernetes cluster tooling";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  inputs.treefmt-nix.url = "github:numtide/treefmt-nix";
  inputs.treefmt-nix.inputs.nixpkgs.follows = "nixpkgs";

  outputs =
    {
      self,
      nixpkgs,
      treefmt-nix,
      ...
    }:
    let
      systems = [
        "aarch64-darwin"
        "aarch64-linux"
        "x86_64-linux"
      ];
      treefmtFor =
        system:
        treefmt-nix.lib.evalModule nixpkgs.legacyPackages.${system} {
          projectRootFile = "flake.nix";

          programs.mdformat.enable = true;
          programs.nixfmt.enable = true;
          programs.shfmt.enable = true;
          programs.yamlfmt.enable = true;

          settings.formatter.shfmt.includes = [
            "*.sh"
            "scripts/k"
            "scripts/k.completions"
          ];
          settings.formatter.yamlfmt.excludes = [
            "argocd/charts/application/templates/*.yaml"
            "secrets/*.yaml"
          ];
          settings.formatter.yamlfmt.includes = [
            "*.yaml"
            "*.yml"
            "*.yaml.example"
          ];
        };
    in
    {
      formatter = nixpkgs.lib.genAttrs systems (system: (treefmtFor system).config.build.wrapper);

      checks = nixpkgs.lib.genAttrs systems (system: {
        formatting = (treefmtFor system).config.build.check self;
      });

      devShells = nixpkgs.lib.genAttrs systems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
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
        }
      );
    };
}
