{
  description = "smonoscr's flake for nixos and home-manager";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable"; # default
    #nixpkgs.url = "github:NixOS/nixpkgs/0196c0175e9191c474c26ab5548db27ef5d34b05"; # default
    #nixpkgs-private.url = "github:smonoscr/nixpkgs/nixos-unstable"; # testing private
    nixpkgs-small.url = "github:NixOS/nixpkgs/nixos-unstable-small"; # faster
    #nixpkgs-git.url = "github:NixOS/nixpkgs/master"; # better not
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-24.11"; # current stable

    systems.url = "github:nix-systems/x86_64-linux"; # or default-linux

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

    nix-gaming = {
      url = "github:fufexan/nix-gaming";
      inputs.nixpkgs.follows = "nixpkgs";
    };

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
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sherlock.url = "github:Skxxtz/sherlock";

    quickshell = {
      url = "git+https://git.outfoxxed.me/outfoxxed/quickshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };

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
      url = "git+ssh://git@codeberg.org/smonoscr/nixsecrets.git";
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
      inherit (inputs.nixpkgs) lib;
      mylib = import "${self}/lib" { inherit lib; };
      forAllSystems = lib.genAttrs (import systems);
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
            inherit inputs outputs mylib;
          };
          modules = [
            ./hosts/desktop/configuration.nix
          ];
        };
      };
    };
}
