{
  description = "simonoscr's flake for nixos and home-manager";

  nixConfig = {
    substituters = [
      "https://cache.nixos.org?priority=10"
      "https://nix-community.cachix.org"
      "https://hyprland.cachix.org"
      "https://yazi.cachix.org"
      "https://simonoscr.cachix.org"
    ];
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
      "yazi.cachix.org-1:Dcdz63NZKfvUCbDGngQDAZq6kOroIrFoyO064uvLh8k="
      "simonoscr.cachix.org-1:pTFtYU3a9SXL+Fw6S3sZ8uk+Vd33Yoothd771oGNJBE="
    ];
  };

  inputs = {
    systems.url = "github:nix-systems/default-linux";

    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

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
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };

    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    firefox-addons = {
      url = "gitlab:rycee/nur-expressions?dir=pkgs/firefox-addons";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixvim = {
      url = "github:nix-community/nixvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hyprland = {
      url = "git+https://github.com/hyprwm/Hyprland?submodules=1";
    };
    hyprland-plugins = {
      url = "github:hyprwm/hyprland-plugins";
      inputs.hyprland.follows = "hyprland";
    };
    hyprlock = {
      url = "github:hyprwm/hyprlock";
      inputs = {
        hyprlang.follows = "hyprland/hyprlang";
        nixpkgs.follows = "hyprland/nixpkgs";
        systems.follows = "hyprland/systems";
      };
    };
    hypridle = {
      url = "github:hyprwm/hypridle";
      inputs = {
        hyprlang.follows = "hyprland/hyprlang";
        nixpkgs.follows = "hyprland/nixpkgs";
        systems.follows = "hyprland/systems";
      };
    };

    yazi.url = "github:sxyazi/yazi";

    ags = {
      url = "github:Aylur/ags";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    impermanence.url = "github:nix-community/impermanence";

    # private secrets repo
    nixsecrets = {
      url = "git+ssh://git@gitlab.com/simonoscr/nixsecrets.git?ref=main&shallow=1";
      flake = false;
    };
  };

  outputs =
    inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" ];

      imports = [ inputs.pre-commit-hooks.flakeModule ];

      perSystem =
        { config, pkgs, ... }:
        {
          pre-commit = {
            settings = {
              excludes = [
                "flake.lock"
                "CHANGELOG.md"
                "LICENSE"
              ];
              src = ./.;
              hooks = {
                nixfmt = {
                  enable = true;
                  package = pkgs.nixfmt-rfc-style;
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

                pre-commit-hook-ensure-sops.enable = true;
              };
            };
          };
          devShells.default = pkgs.mkShell rec {
            name = "nixfiles";
            nativeBuildInputs = config.pre-commit.settings.enabledPackages;
            shellHook = ''
              ${config.pre-commit.installationScript}
              echo -e "\n\033[1;36m  Welcome to the \033[1;33m'${name}'\033[1;36m devshell  \033[0m\n"
            '';
          };
          formatter = pkgs.nixfmt-rfc-style;
        };

      flake = {
        nixosConfigurations = {
          desktop = inputs.nixpkgs.lib.nixosSystem {
            system = "x86_64-linux";
            specialArgs = {
              inherit inputs;
            };
            modules = [
              ./hosts/desktop/configuration.nix
              #inputs.home-manager.nixosModules.home-manager
              #{
              #  home-manager = {
              #    users.simon.imports = [ ./home/simon/home.nix ];
              #  };
              #}
            ];
          };
          server = inputs.nixpkgs.lib.nixosSystem {
            system = "x86_64-linux";
            specialArgs = {
              inherit inputs;
            };
            modules = [ ./hosts/server/configuration.nix ];
          };
          #desktopISO = inputs.nixpkgs.lib.nixosSystem {
          #  system = "x86_64-linux";
          #  specialArgs = {
          #    inherit inputs;
          #  };
          #  modules = [
          #    ./images/desktopiso.nix
          #    inputs.home-manager.nixosModules.home-manager
          #    {
          #      home-manager = {
          #        extraSpecialArgs = {
          #          inherit inputs;
          #        };
          #        users.simon.imports = [ ./home/simon/home.nix ];
          #      };
          #    }
          #    "${inputs.nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-base.nix"
          #  ];
          #};
        };
      };
    };
}
