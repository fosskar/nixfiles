{
  description = "simonoscr's flake for nixos and home-manager";

  inputs = {
    systems.url = "github:nix-systems/default-linux";

    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-small.url = "github:NixOS/nixpkgs/nixos-unstable-small"; # faster

    chaotic.url = "github:chaotic-cx/nyx/nyxpkgs-unstable";

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
      inputs.nixpkgs.follows = "nixpkgs-small";
    };

    firefox-addons = {
      url = "gitlab:rycee/nur-expressions?dir=pkgs/firefox-addons";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixvim = {
      url = "github:nix-community/nixvim";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-parts.follows = "flake-parts";
        devshell.follows = "";
        flake-compat.follows = "";
        git-hooks.follows = "";
        nix-darwin.follows = "";
        treefmt-nix.follows = "";
      };
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        nixpkgs-stable.follows = "";
      };
    };

    zen-browser = {
      url = "github:fufexan/zen-browser-flake";
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
      inputs.nixpkgs.follows = "nixpkgs";
    };

    impermanence.url = "github:nix-community/impermanence";

    tailray = {
      url = "github:NotAShelf/tailray";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # private secrets repo
    nixsecrets = {
      url = "git+ssh://git@gitlab.com/simonoscr/nixsecrets.git?ref=main&shallow=1";
      flake = false;
    };

    agsdotfiles = {
      url = "github:Aylur/dotfiles";
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
