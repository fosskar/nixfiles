{
  description = "simonoscr's flake";

  inputs = {
    # nixpkgs
    nixpkgs.url = "git+https://github.com/NixOS/nixpkgs?shallow=1&ref=nixos-unstable";
    nixpkgs-stable.url = "git+https://github.com/NixOS/nixpkgs?shallow=1&ref=nixos-25.11";
    #nixpkgs-private.url = "github:simonoscr/nixpkgs/nixos-unstable"; # testing private
    #nixpkgs-small.url = "github:NixOS/nixpkgs/nixos-unstable-small"; # faster

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    clan-community = {
      url = "git+https://git.clan.lol/clan/clan-community?shallow=1";
      inputs.clan-core.follows = "clan-core";
      inputs.flake-parts.follows = "flake-parts";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.systems.follows = "systems";
      inputs.treefmt-nix.follows = "treefmt-nix";
    };

    clan-core = {
      url = "git+https://git.clan.lol/clan/clan-core?shallow=1";
      #url = "https://git.clan.lol/clan/clan-core/archive/main.tar.gz";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-parts.follows = "flake-parts";
      inputs.sops-nix.follows = "sops-nix";
      inputs.treefmt-nix.follows = "treefmt-nix";
      inputs.disko.follows = "disko";
      inputs.systems.follows = "systems";
    };

    # system
    systems.url = "github:nix-systems/default-linux";

    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };

    import-tree.url = "github:denful/import-tree";

    srvos = {
      url = "github:nix-community/srvos";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    #nix-cachyos-kernel = {
    #  url = "github:xddxdd/nix-cachyos-kernel";
    #  inputs.nixpkgs.follows = "nixpkgs";
    #  inputs.flake-parts.follows = "flake-parts";
    #  inputs.flake-compat.follows = "";
    #};

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # impermanence.url = "github:nix-community/impermanence";
    preservation.url = "github:nix-community/preservation";

    lanzaboote = {
      url = "github:nix-community/lanzaboote";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-hardware.url = "github:NixOS/nixos-hardware";

    tangled = {
      url = "git+https://tangled.org/tangled.org/core";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-compat.follows = "";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # format and lint
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    buildbot-nix = {
      url = "github:nix-community/buildbot-nix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.treefmt-nix.follows = "treefmt-nix";
    };

    niks3 = {
      url = "github:Mic92/niks3";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.treefmt-nix.follows = "treefmt-nix";
    };

    gitea-mq = {
      url = "github:Mic92/gitea-mq";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.treefmt-nix.follows = "treefmt-nix";
    };

    # browser
    zed = {
      url = "github:zed-industries/zed";
      inputs.flake-parts.follows = "flake-parts";
    };

    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake/beta";
      #url = "github:0xc000022070/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };

    # gaming
    nix-gaming = {
      url = "github:fufexan/nix-gaming";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-parts.follows = "flake-parts";
    };

    # llm
    llm-agents = {
      url = "github:numtide/llm-agents.nix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.treefmt-nix.follows = "treefmt-nix";
      inputs.flake-parts.follows = "flake-parts";
      inputs.systems.follows = "systems";
    };
    opencrow = {
      url = "github:fosskar/opencrow";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.treefmt-nix.follows = "treefmt-nix";
    };
    mics-skills = {
      url = "github:Mic92/mics-skills";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.treefmt-nix.follows = "treefmt-nix";
    };
    hunk = {
      url = "github:modem-dev/hunk";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # wm
    niri-flake = {
      url = "github:sodiboo/niri-flake";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.nixpkgs-stable.follows = "nixpkgs-stable";
    };
    noctalia = {
      url = "github:noctalia-dev/noctalia-shell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    noctalia-v5 = {
      url = "github:noctalia-dev/noctalia-shell/v5";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    noctalia-plugins = {
      url = "github:Mic92/noctalia-plugins";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    wiki = {
      url = "git+https://codeberg.org/fosskar/wiki.git?shallow=1";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-parts.follows = "flake-parts";
      inputs.systems.follows = "systems";
      inputs.treefmt-nix.follows = "treefmt-nix";
    };

  };

  outputs =
    inputs@{
      self,
      flake-parts,
      ...
    }:
    let
      inherit (inputs.nixpkgs) lib;
      mylib = import ./lib { inherit lib self; };

      flakeModules = mylib.scanFlakeModules ./.;
    in
    flake-parts.lib.mkFlake { inherit inputs; } {

      systems = import inputs.systems;

      flake.lib = mylib;

      imports = [
        inputs.clan-core.flakeModules.default
        inputs.flake-parts.flakeModules.modules
        (inputs.import-tree ./modules)
      ]
      ++ flakeModules;

      perSystem =
        { config, inputs', ... }:
        {

          # make pkgs available in perSystem
          _module.args.pkgs = inputs'.nixpkgs.legacyPackages;

          # disabled: clan-core now propagates pkgsFor into nixosConfigurations,
          # which conflicts with nixpkgs.config set in nixos modules.
          # not needed anyway since clan-core.inputs.nixpkgs follows our nixpkgs.
          #clan.pkgs = inputs'.nixpkgs.legacyPackages;

          formatter = config.treefmt.build.wrapper;
        };
    };
}
