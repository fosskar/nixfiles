{
  description = "simonoscr's flake for nixos and home-manager";

  inputs = {
    systems.url = "github:nix-systems/default-linux";

    # nixos unstable
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    # home-manager
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    pre-commit-hooks = {
      url = "github:cachix/pre-commit-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    flake-parts = {
      url = "github:hercules-ci/flake-parts";
    };

    # firefox addons
    firefox-addons = {
      url = "gitlab:rycee/nur-expressions?dir=pkgs/firefox-addons";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # nix neovim
    nixvim = {
      url = "github:nix-community/nixvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # secrets operations nix
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    matugen = {
      url = "github:InioX/matugen/module";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # hyprland
    hyprland = {
      url = "git+https://github.com/hyprwm/Hyprland?submodules=1";
    };
    hyprland-plugins = {
      url = "github:hyprwm/hyprland-plugins";
      inputs.hyprland.follows = "hyprland";
    };

    yazi.url = "github:sxyazi/yazi";

    # aylur-gtk-shell
    ags = {
      url = "github:Aylur/ags";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixhelm.url = "github:farcaller/nixhelm";
    nix-kube-generators.url = "github:farcaller/nix-kube-generators";
  };

  outputs = inputs:
    inputs.flake-parts.lib.mkFlake {inherit inputs;} {
      systems = ["x86_64-linux"];

      imports = [
        ./pre-commit-hooks.nix
      ];

      perSystem = {
        config,
        pkgs,
        ...
      }: let
        kubelib = inputs.nix-kube-generators.lib {inherit pkgs;};
      in {
        devShells.default = pkgs.mkShell {
          nativeBuildInputs = with pkgs; [
            alejandra
            deadnix
            statix
            git
            nodePackages.prettier
          ];
          name = "nixfiles";
          DIRENV_LOG_FORMAT = "";
          shellHook = ''
            ${config.pre-commit.installationScript}
            echo 1>&2 "Welcome to the development shell!"
          '';
        };
        formatter = pkgs.alejandra;

        packages.default = pkgs.writeShellScriptBin "deploy-argo" ''
          ${kubelib.buildHelmChart {
            name = "argocd";
            chart = (inputs.nixhelm.charts {inherit pkgs;}).argoproj.argo-cd;
            namespace = "argocd";
          }}
        '';
      };

      flake = {
        nixosConfigurations = {
          desktop = inputs.nixpkgs.lib.nixosSystem {
            system = "x86_64-linux";
            specialArgs = {inherit inputs;};
            modules = [
              ./hosts/desktop/configuration.nix
              inputs.home-manager.nixosModules.home-manager
              {
                home-manager = {
                  extraSpecialArgs = {inherit inputs;};
                  users.simon = import ./home/profiles/simon/home.nix;
                };
              }
            ];
          };
          server = inputs.nixpkgs.lib.nixosSystem {
            system = "x86_64-linux";
            specialArgs = {inherit inputs;};
            modules = [
              ./hosts/server/configuration.nix
              inputs.home-manager.nixosModules.home-manager
              {
                home-manager = {
                  extraSpecialArgs = {inherit inputs;};
                  users.oscar = import ./home/profiles/oscar/home.nix;
                };
              }
            ];
          };
        };
        homeConfigurations = {
          work = inputs.home-manager.lib.homeManagerConfiguration {
            pkgs = inputs.nixpkgs.legacyPackages."x86_64-linux";
            extraSpecialArgs = {inherit inputs;};
            modules = [./home/profiles/work/home.nix];
          };
        };
      };
    };
}
