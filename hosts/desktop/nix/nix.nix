{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
{
  nix =
    let
      flakeInputs = lib.filterAttrs (_: v: lib.isType "flake" v) inputs;
    in
    {
      package = pkgs.nixVersions.latest; # nixVersions.latest, lix
      # pin the registry to avoid downloading and evaling a new nixpkgs version every time
      # flakeInputs filters out non-flake inputs from system flake registry
      registry = lib.mapAttrs (_: v: { flake = v; }) flakeInputs;

      ## the above solution is a more dynamic approach and not only registers all flake inputs (including self) but furthermore also filters out non-flake inputs
      # registry.<name>.flake = inputs.self;

      # set the path for channels compat
      nixPath = lib.mapAttrsToList (key: _: "${key}=flake:${key}") config.nix.registry;

      channel.enable = false;

      settings = {
        experimental-features = [
          "nix-command"
          "flakes"
        ];
        # Whether to accept nix configuration from a flake
        # without displaying a Y/N prompt. For those obtuse
        # enough to keep this true, I wish the best of luck.
        accept-flake-config = false;
        cores = 0;
        max-jobs = "auto";
        connect-timeout = 5;
        http-connections = 35;
        auto-optimise-store = true;
        builders-use-substitutes = true;
        allowed-users = [
          "root"
          "@wheel"
        ];
        trusted-users = [
          "root"
          "@wheel"
        ];
        system-features = [
          "kvm"
          "big-parallel"
        ];
        flake-registry = "/etc/nix/registry.json";
        # Continue building derivations even if one fails
        keep-going = true;
        # for direnv garbage-collection roots
        keep-derivations = true;
        keep-outputs = true;
        fallback = true;
        # Don't warn me that my git tree is dirty, I know.
        warn-dirty = false;
        nix-path = [ "nixpkgs=${pkgs.path}" ]; # FIXME https://discourse.nixos.org/t/24-05-add-flake-to-nix-path/46310/9
      };
      gc = {
        automatic = false; # because i am using nh.clean
        #dates = "weekly";
        #options = "--delete-older-than 1w";
      };
      optimise = {
        automatic = true;
        dates = [ "04:00" ];
      };
      extraOptions = ''
        !include ${config.sops.secrets."nix/access-tokens/github".path}
      '';
    };
}
