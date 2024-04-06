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
      url = github:nix-community/NUR;
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
      url = "github:/InioX/Matugen";
    };

    # hyprland
    hyprland = {
      url = "github:hyprwm/Hyprland";
    };
    hyprland-plugins = {
      url = "github:hyprwm/hyprland-plugins";
      inputs.hyprland.follows = "hyprland";
    };
    hypridle = {
      url = "github:hyprwm/hypridle";
    };
    hyprlock = {
      url = "github:hyprwm/hyprlock";
    };

    # nyx
    chaotic = {
      url = "github:chaotic-cx/nyx/nyxpkgs-unstable";
    };

    nix-gaming = {
      url = "github:fufexan/nix-gaming/6e2db2c21be525330942380e2e839277574404fa";
    };

    #nixpkgs-wayland = {
    #  url = "github:nix-community/nixpkgs-wayland";
    #  inputs.nixpkgs.follows = "nixpkgs";
    #};

    # aylur-gtk-shell
    ags = {
      url = "github:Aylur/ags";
    };
  };

  outputs = {
    self,
    nixpkgs,
    home-manager,
    sops-nix,
    hyprland,
    hyprland-plugins,
    hypridle,
    hyprlock,
    nur,
    chaotic,
    nix-gaming,
    nixvim,
    firefox-addons,
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
          #{nixpkgs.overlays = [inputs.nixpkgs-wayland.overlay];}
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = {inherit inputs;};
            home-manager.users.simon = import ./home/profiles/simon/home.nix;
          }
        ];
      };
      "voyager" = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = {inherit inputs;};
        modules = [
          {nixpkgs.overlays = [nur.overlay];}
          ./hosts/voyager/configuration.nix
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            #home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = {inherit inputs;};
            home-manager.users.simon = import ./home/profiles/oscar/home.nix;
          }
        ];
      };
    };

    # standalone home-manager configuration entrypoint
    # available through 'home-manager --flake .#your-username@your-hostname'
    homeConfigurations = {
      # server user
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
