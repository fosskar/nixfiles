{
  description = "simonoscr's flake for nixos and home-manager";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable"; # default
    nixpkgs-small.url = "github:NixOS/nixpkgs/nixos-unstable-small"; # faster
    nixpkgs-git.url = "github:NixOS/nixpkgs/master"; # current master on git
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-24.05"; # current stable

    systems.url = "github:nix-systems/x86_64-linux";

    chaotic.url = "github:chaotic-cx/nyx/nyxpkgs-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    pre-commit-hooks = {
      url = "github:cachix/pre-commit-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs-small";
    };

    firefox-addons = {
      url = "gitlab:rycee/nur-expressions?dir=pkgs/firefox-addons";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        nixpkgs-stable.follows = "";
      };
    };

    agenix = {
      url = "github:ryantm/agenix";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        darwin.follows = "";
      };
    };

    zen-browser = {
      url = "gitlab:simonoscr/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hyprland = {
      url = "github:hyprwm/Hyprland";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        systems.follows = "systems";
      };
    };

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

    ags = {
      url = "github:Aylur/ags";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        systems.follows = "systems";
      };
    };

    impermanence.url = "github:nix-community/impermanence";

    tailray = {
      url = "github:NotAShelf/tailray";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # private secrets repo
    nixsecrets = {
      url = "git+ssh://git@gitlab.com/simonoscr/nixsecrets";
    };

    agsdotfiles = {
      url = "github:Aylur/dotfiles";
      flake = false;
    };

    # gaming
    nix-gaming.url = "github:fufexan/nix-gaming";
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
      eachSystem = nixpkgs.lib.genAttrs (import systems);
    in
    {
      checks = eachSystem (system: {
        pre-commit-check = inputs.pre-commit-hooks.lib.${system}.run {
          excludes = [
            "flake.lock"
            "CHANGELOG.md"
            "LICENSE"
          ];
          src = ./.;
          hooks = {
            nixfmt-rfc-style = {
              enable = true;
            };
            prettier = {
              enable = true;
              fail_fast = true;
              excludes = [
                ".md"
                ".nix"
                ".yaml"
                ".yml"
              ];
              settings = {
                write = true;
              };
            };
            deadnix = {
              enable = true;
              fail_fast = true;
            };
            #statix = {
            #  enable = true;
            #  fail_fast = true;
            #};
            pre-commit-hook-ensure-sops.enable = true;
          };
        };
      });
      devShells = eachSystem (system: {
        default = nixpkgs.legacyPackages.${system}.mkShell {
          name = "nixfiles";
          inherit (self.checks.${system}.pre-commit-check) shellHook;
          buildInputs = self.checks.${system}.pre-commit-check.enabledPackages;
        };
      });

      formatter = eachSystem (system: nixpkgs.legacyPackages.${system}.nixfmt-rfc-style);

      #overlays = import ./overlays { inherit inputs; };

      #packages = eachSystem (
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
    };
}
