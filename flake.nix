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
  };

  outputs = inputs:
    inputs.flake-parts.lib.mkFlake {inherit inputs;} {
      systems = ["x86_64-linux"];

      imports = [
        inputs.pre-commit-hooks.flakeModule
      ];

      perSystem = {
        config,
        pkgs,
        ...
      }: {
        pre-commit.settings = {
          excludes = [
            "flake.lock"
            "CHANGELOG.md"
            "LICENSE"
          ];
          hooks = {
            alejandra = {
              enable = true;
              fail_fast = true;
              settings = {
                check = false;
              };
            };

            statix = {
              enable = true;
              fail_fast = true;
            };

            deadnix = {
              enable = true;
              fail_fast = true;
              settings = {
                edit = true;
              };
            };

            yamllint = {
              enable = true;
              fail_fast = true;
              settings = {
                format = "colored";
                preset = "relaxed";
                configuration = ''
                  ---

                  extends: relaxed

                  rules:
                    braces:
                      level: warning
                      max-spaces-inside: 1
                    brackets:
                      level: warning
                      max-spaces-inside: 1
                    colons:
                      level: warning
                    commas:
                      level: warning
                    comments: disable
                    comments-indentation: disable
                    document-start: disable
                    empty-lines:
                      level: warning
                    hyphens:
                      level: warning
                    indentation:
                      level: warning
                      indent-sequences: consistent
                    line-length: disable
                    truthy: disable
                '';
              };
            };

            #typos = {
            #  enable = true;
            #  settings = {
            #    write = true;
            #    configPath = "./.typos.toml";
            #  };
            #};

            #prettier = {
            #  enable = true;
            #  fail_fast = true;
            #  excludes = [".js" ".md" ".ts" ".scss" ".css"];
            #  settings = {
            #    write = true;
            #  };
            #};

            shellcheck = {
              enable = true;
              excludes = ["png"];
              types_or = ["shell"];
            };

            pre-commit-hook-ensure-sops.enable = true;
          };
        };
        devShells.default = pkgs.mkShell {
          packages = [
            pkgs.alejandra
            pkgs.deadnix
            pkgs.statix
            pkgs.git
            pkgs.nodePackages.prettier
          ];
          name = "nixfiles";
          DIRENV_LOG_FORMAT = "";
          shellHook = ''
            ${config.pre-commit.installationScript}
            echo 1>&2 "Welcome to the development shell!"
          '';
        };
        formatter = pkgs.alejandra;
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
      };
    };
}
