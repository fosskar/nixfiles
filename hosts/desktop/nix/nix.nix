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
      #registry = mappedRegistry;

      ## the above solution is a more dynamic approach and not only registers all flake inputs (including self) but furthermore also filters out non-flake inputs
      # registry.<name>.flake = inputs.self;

      # This will additionally add your inputs to the system's legacy channels
      # Making legacy nix commands consistent as well
      nixPath = lib.mapAttrsToList (key: _: "${key}=flake:${key}") config.nix.registry;

      channel.enable = false;

      daemonCPUSchedPolicy = "idle";

      settings = {
        experimental-features = [
          "nix-command"
          "flakes"
        ];
        # Whether to accept nix configuration from a flake
        # without displaying a Y/N prompt. For those obtuse
        # enough to keep this true, I wish the best of luck.
        accept-flake-config = false;
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
