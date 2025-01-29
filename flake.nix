{
  description = "simonoscr's flake for nixos and home-manager";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable"; # default
    nixpkgs-small.url = "github:NixOS/nixpkgs/nixos-unstable-small"; # faster
    #nixpkgs-git.url = "github:NixOS/nixpkgs/master"; # better not
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-24.11"; # current stable

    systems.url = "github:nix-systems/default-linux";

    # nix-community
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs-small";
    };

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    impermanence.url = "github:nix-community/impermanence";

    chaotic.url = "github:chaotic-cx/nyx/nyxpkgs-unstable";

    pre-commit-hooks = {
      url = "github:cachix/pre-commit-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    zen-browser = {
      url = "github:youwen5/zen-browser-flake";
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
        hyprgraphics.follows = "hyprland/hyprgraphics";
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
      inputs.nixpkgs.follows = "nixpkgs";
    };
    anyrun = {
      url = "github:anyrun-org/anyrun";
    };

    # cosmic
    nixos-cosmic = {
      url = "github:lilyinstarlight/nixos-cosmic";
      #inputs.nixpkgs.follows = "nixos-cosmic/nixpkgs";
    };
    home-manager-cosmic.url = "github:tristanbeedell/hm-cosmic";

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

      templates = import "${self}/templates" { inherit self; };

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

        k3s-control-1 = nixpkgs.lib.nixosSystem {
          specialArgs = {
            inherit inputs outputs;
          };
          modules = [ ./hosts/k8s/k3s-control-1/configuration.nix ];
        };

        k3s-worker-1 = nixpkgs.lib.nixosSystem {
          specialArgs = {
            inherit inputs outputs;
          };
          modules = [ ./hosts/k8s/k3s-worker-1/configuration.nix ];
        };

        k3s-worker-2 = nixpkgs.lib.nixosSystem {
          specialArgs = {
            inherit inputs outputs;
          };
          modules = [ ./hosts/k8s/k3s-worker-2/configuration.nix ];
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
      colmena = {
        meta = {
          name = "k8s";
          nixpkgs = import inputs.nixpkgs {
            system = "aarch64-linux";
          };
          specialArgs = {
            inherit inputs;
          };
        };

        k3s-control-1 = {
          deployment = {
            targetHost = "188.245.201.191";
            tags = [ "control" ];
          };
          imports = [ ./hosts/k8s/k3s-control-1/configuration.nix ];
          time.timeZone = "Europe/Berlin";
        };
        k3s-worker-1 = {
          deployment = {
            targetHost = "128.140.113.184";
            tags = [ "worker" ];
          };
          imports = [ ./hosts/k8s/k3s-worker-1/configuration.nix ];
          time.timeZone = "Europe/Berlin";
        };
        k3s-worker-2 = {
          deployment = {
            targetHost = "138.201.88.53";
            targetPort = 22;
            tags = [ "worker" ];
          };
          imports = [ ./hosts/k8s/k3s-worker-2/configuration.nix ];
          time.timeZone = "Europe/Berlin";
        };
      };
    };
}
