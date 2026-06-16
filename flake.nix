{
  description = "nixfiles";

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

    home-git-clone = {
      url = "github:rytswd/home-git-clone";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    pkgs-by-name-for-flake-parts.url = "github:drupol/pkgs-by-name-for-flake-parts";

    srvos = {
      url = "github:nix-community/srvos";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    preservation.url = "github:nix-community/preservation";

    lanzaboote = {
      url = "github:nix-community/lanzaboote";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-hardware.url = "github:NixOS/nixos-hardware";
    nixos-hardware.inputs.nixpkgs.follows = "nixpkgs";

    nix-topology.url = "github:oddlama/nix-topology";
    nix-topology.inputs.nixpkgs.follows = "nixpkgs";
    nix-topology.inputs.flake-parts.follows = "flake-parts";

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # format and lint
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixbot = {
      url = "github:Mic92/nixbot";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.treefmt-nix.follows = "treefmt-nix";
    };

    niks3 = {
      url = "github:Mic92/niks3";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.treefmt-nix.follows = "treefmt-nix";
    };

    # browser nightly
    #zed-nightly = {
    #  url = "github:zed-industries/zed";
    #  inputs.flake-parts.follows = "flake-parts";
    #};

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
    hermes-agent = {
      url = "github:NousResearch/hermes-agent";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-parts.follows = "flake-parts";
    };
    mics-skills = {
      url = "github:Mic92/mics-skills";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.treefmt-nix.follows = "treefmt-nix";
    };
    spaces.url = "github:generational-infrastructure/spaces-os";
    spaces.inputs.home-manager.follows = "home-manager";
    spaces.inputs.llm-agents.follows = "llm-agents";
    spaces.inputs.nixpkgs.follows = "nixpkgs";
    spaces.inputs.systems.follows = "systems";
    spaces.inputs.treefmt-nix.follows = "treefmt-nix";
    spaces.inputs.voxtype.follows = "voxtype";

    voxtype = {
      url = "github:peteonrails/voxtype";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # wm
    niri-nix = {
      url = "git+https://codeberg.org/BANanaD3V/niri-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    noctalia = {
      url = "github:noctalia-dev/noctalia-shell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    noctalia-greeter = {
      url = "github:noctalia-dev/noctalia-greeter";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    noctalia-legacy = {
      url = "github:noctalia-dev/noctalia-shell/legacy-v4";
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
      nflib = import ./lib { inherit lib self; };

      flakeModules = nflib.scanFlakeModules ./.;
    in
    flake-parts.lib.mkFlake { inherit inputs; } {

      _module.args.rootPath = ./.;

      imports = [
        inputs.flake-parts.flakeModules.modules
        (inputs.import-tree ./modules)
      ]
      ++ flakeModules;
    };
}
