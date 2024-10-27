{
  description = "simonoscr's flake for nixos and home-manager";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable"; # default
    nixpkgs-small.url = "github:NixOS/nixpkgs/nixos-unstable-small"; # faster
    nixpkgs-git.url = "github:NixOS/nixpkgs/master"; # current master on git
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-24.05"; # current stable

    systems.url = "github:nix-systems/x86_64-linux";

    # nix-community
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs-small";
    };
    impermanence.url = "github:nix-community/impermanence";

    chaotic.url = "github:chaotic-cx/nyx/nyxpkgs-unstable";

    pre-commit-hooks = {
      url = "github:cachix/pre-commit-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # gaming
    nix-gaming = {
      url = "github:fufexan/nix-gaming";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # hyprland
    hyprland.url = "github:hyprwm/Hyprland";
    hyprland-plugins = {
      url = "github:hyprwm/hyprland-plugins";
      inputs.hyprland.follows = "hyprland";
    };
    hyprlock = {
      url = "github:hyprwm/hyprlock";
      inputs = {
        hyprlang.follows = "hyprland/hyprlang";
        hyprutils.follows = "hyprland/hyprutils";
        nixpkgs.follows = "hyprland/nixpkgs";
        systems.follows = "hyprland/systems";
      };
    };
    hypridle = {
      url = "github:hyprwm/hypridle";
      inputs = {
        hyprlang.follows = "hyprland/hyprlang";
        hyprutils.follows = "hyprland/hyprutils";
        nixpkgs.follows = "hyprland/nixpkgs";
        systems.follows = "hyprland/systems";
      };
    };
    hyprpanel = {
      url = "github:Jas-SinghFSU/HyprPanel";
    };

    # ags
    ags = {
      url = "github:Aylur/ags";
      inputs = {
        nixpkgs.follows = "nixpkgs";
      };
    };
    agsdotfiles = {
      url = "github:Aylur/dotfiles";
      flake = false;
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
        nixpkgs-stable.follows = "";
      };
    };
    nixsecrets = {
      url = "git+ssh://git@gitlab.com/simonoscr/nixsecrets";
    };

    # misc
    firefox-addons = {
      url = "gitlab:rycee/nur-expressions?dir=pkgs/firefox-addons";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    tailray = {
      url = "github:NotAShelf/tailray";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    zen-browser = {
      url = "gitlab:simonoscr/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      systems,
      nixpkgs,
      ...
    }@inputs:
    let
      inherit (self) outputs;
      forAllSystems = nixpkgs.lib.genAttrs (import systems);
    in
    {
      checks = forAllSystems (system: {
        pre-commit-check = import "${self}/checks/pre-commit-hook" { inherit self inputs system; };
      });

      devShells = forAllSystems (system: {
        default = nixpkgs.legacyPackages.${system}.mkShell {
          name = "nixfiles";
          inherit (self.checks.${system}.pre-commit-check) shellHook;
          buildInputs = self.checks.${system}.pre-commit-check.enabledPackages;
        };
      });

      formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.nixfmt-rfc-style);

      #overlays = import "${self}/overlays" { inherit self; }; # no

      #packages = forAllSystems (
      #  system:
      #  let
      #    pkgs = import nixpkgs { inherit system; };
      #  in
      #  {
      #    offline-iso = nixos-generators.nixosGenerate {
      #      system = system;
      #      specialArgs = {
      #        pkgs = pkgs;
      #      };
      #      modules = [
      #        ./images/offline-iso.nix
      #      ];
      #      format = "iso";
      #    };
      #  }
      #);

      nixosConfigurations = {
        desktop = nixpkgs.lib.nixosSystem {
          specialArgs = {
            inherit inputs outputs;
          };
          modules = [
            ./hosts/desktop/configuration.nix
          ];
        };

        server = nixpkgs.lib.nixosSystem {
          specialArgs = {
            inherit inputs outputs;
          };
          modules = [ ./hosts/server/configuration.nix ];
        };

        installer-iso = nixpkgs.lib.nixosSystem {
          specialArgs = {
            inherit inputs outputs;
          };
          modules = [
            ./images/installer-iso.nix
          ];
        };
      };

      templates = import "${self}/templates" { inherit self; };
    };
}
