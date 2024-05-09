{
  description = "simonoscr's flake for nixos and home-manager";

  inputs = {
    # nixos unstable
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    ## nix unstable
    #nix = {
    #  url = "github:NixOS/nix";
    #};

    # home-manager
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # utils for nix flake
    flake-utils = {
      url = "github:numtide/flake-utils";
    };

    # nur nix user repository
    nur = {
      url = "github:nix-community/NUR";
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
    hyprlock = {
      url = "github:hyprwm/hyprlock";
    };

    yazi.url = "github:sxyazi/yazi";

    alejandra = {
      url = "github:kamadorueda/alejandra/3.0.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-gaming = {
      url = "github:fufexan/nix-gaming/6e2db2c21be525330942380e2e839277574404fa";
    };

    # aylur-gtk-shell
    ags = {
      url = "github:Aylur/ags";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    nixpkgs,
    home-manager,
    nur,
    nixos-generators,
    ...
  } @ inputs: let
    system = "x86_64-linux";
  in {
    # nixos configuration entrypoint
    # available through 'nixos-rebuild --flake .#your-hostname'
    nixosConfigurations = {
      "desktop" = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = {inherit inputs;};
        modules = [
          ./hosts/desktop/configuration.nix
          home-manager.nixosModules.home-manager
          {
            home-manager = {
              extraSpecialArgs = {inherit inputs;};
              users.simon = import ./home/profiles/simon/home.nix;
            };
          }
        ];
      };
      "server" = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = {inherit inputs;};
        modules = [
          {nixpkgs.overlays = [nur.overlay];}
          ./hosts/server/configuration.nix
          home-manager.nixosModules.home-manager
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
}
