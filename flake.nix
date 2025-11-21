{
  description = "smonoscr's flake";

  inputs = {
    # nixpkgs
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable"; # default
    #nixpkgs.url = "github:NixOS/nixpkgs/7fd36ee82c0275fb545775cc5e4d30542899511d"; # default pinned commit hash
    #nixpkgs.url = "github:smonoscr/nixpkgs/vulkanlayer-anti-lag"; # testing private
    nixpkgs-small.url = "github:NixOS/nixpkgs/nixos-unstable-small"; # faster
    #nixpkgs-git.url = "github:NixOS/nixpkgs/master"; # better not
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-25.05"; # current stable

    # system
    systems.url = "github:nix-systems/x86_64-linux"; # or default-linux
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    impermanence.url = "github:nix-community/impermanence";
    chaotic.url = "github:chaotic-cx/nyx/nyxpkgs-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";

    # format and lint
    git-hooks = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # browser
    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # gaming
    nix-gaming = {
      url = "github:fufexan/nix-gaming/8b636f0470cb263aa1472160457f4b2fba420425";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # wm
    niri-flake = {
      url = "github:sodiboo/niri-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    hyprland = {
      url = "github:hyprwm/Hyprland";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    hyprland-plugins = {
      url = "github:hyprwm/hyprland-plugins";
      inputs.hyprland.follows = "hyprland";
    };

    # quickshell
    quickshell = {
      url = "github:outfoxxed/quickshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    noctalia = {
      url = "github:noctalia-dev/noctalia-shell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    dgop = {
      url = "github:AvengeMedia/dgop";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    dms = {
      url = "github:AvengeMedia/DankMaterialShell";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        dgop.follows = "dgop";
      };
    };

    # secrets
    agenix = {
      url = "github:ryantm/agenix";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        darwin.follows = "";
        home-manager.follows = "home-manager";
        systems.follows = "systems";
      };
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs = {
        nixpkgs.follows = "nixpkgs";
      };
    };

    # private
    nixsecrets = {
      url = "git+ssh://git@codeberg.org/smonoscr/nixsecrets.git";
      flake = false;
    };
    wallpaper = {
      url = "git+ssh://git@codeberg.org/smonoscr/wallpaper.git";
      flake = false;
    };
  };

  outputs =
    inputs@{
      self,
      flake-parts,
      ...
    }:
    flake-parts.lib.mkFlake { inherit inputs; } (
      let
        inherit (inputs.nixpkgs) lib;
        mylib = import "${self}/lib" { inherit lib; };
      in
      {
        imports = [
          ./checks
        ];

        systems = import inputs.systems;

        flake = {
          templates = import "${self}/templates" { inherit self; };

          nixosConfigurations = {
            desktop = inputs.nixpkgs.lib.nixosSystem {
              specialArgs = {
                inherit inputs mylib;
                outputs = self;
              };
              modules = [
                ./hosts/desktop/configuration.nix
              ];
            };
          };
        };

        perSystem =
          {
            pkgs,
            config,
            ...
          }:
          {
            formatter = config.treefmt.build.wrapper;

            devShells.default = pkgs.mkShell {
              name = "nixfiles";
              shellHook = ''
                ${config.pre-commit.installationScript}
              '';
            };
          };
      }
    );
}
