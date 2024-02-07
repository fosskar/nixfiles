{
  description = "simonoscr's flake for nixos and home-manager";

  inputs = {
    # nixos unstable
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

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
      url = github:nix-community/NUR;
    };

    nixos-hardware = {
      url = "github:NixOS/nixos-hardware/master";
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

    # hyprland wm
    hyprland = {
      url = "github:hyprwm/Hyprland";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    hyprland-plugins = {
      url = "github:hyprwm/hyprland-plugins";
      inputs.hyprland.follows = "hyprland";
    };

    # lancache
    lancache = {
      url = "github:boffbowsh/nix-lancache";
    };

    # nyx
    chaotic = {
      url = "github:chaotic-cx/nyx/nyxpkgs-unstable";
    };

    # stylix
    stylix = {
      url = "github:danth/stylix";
    };

    nix-gaming = {
      url = "github:fufexan/nix-gaming";
    };

    #nixpkgs-wayland = {
    #  url = "github:nix-community/nixpkgs-wayland";
    #  inputs.nixpkgs.follows = "nixpkgs";
    #};

    ## aylur-gtk-shell
    #ags = {
    #  url = "github:Aylur/ags";
    #};

    #gBar.url = "github:scorpion-26/gBar";
  };

  outputs = {
    self,
    nixpkgs,
    home-manager,
    sops-nix,
    hyprland,
    hyprland-plugins,
    nur,
    nixos-hardware,
    chaotic,
    lancache,
    stylix,
    nix-gaming,
    ...
  } @ inputs: let
    system = "x86_64-linux";
  in {
    # nixos configuration entrypoint
    # available through 'nixos-rebuild --flake .#your-hostname'
    nixosConfigurations = {
      "cosmos" = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = {inherit inputs;};
        modules = [
          ./hosts/cosmos/configuration.nix
        ];
      };
      "voyager" = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = {inherit inputs;};
        modules = [
          {nixpkgs.overlays = [nur.overlay];}
          ./hosts/voyager/configuration.nix
        ];
      };
    };

    # standalone home-manager configuration entrypoint
    # available through 'home-manager --flake .#your-username@your-hostname'
    homeConfigurations = {
      # personal user
      "simon@cosmos" = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.${system};
        extraSpecialArgs = {inherit inputs;};
        modules = [
          {nixpkgs.overlays = [nur.overlay];}
          # inputs.nixpkgs-wayland.overlay
          ./home/simon/home.nix
        ];
      };
      "oscar@voyager" = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.${system};
        extraSpecialArgs = {inherit inputs;};
        modules = [
          ./home/oscar/home.nix
        ];
      };
      # work user
      "simon@work" = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.${system};
        extraSpecialArgs = {inherit inputs;};
        modules = [
          ./home/work/home.nix
        ];
      };
    };
  };
}
