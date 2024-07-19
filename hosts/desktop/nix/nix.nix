{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
{
  nix = {
    #package = pkgs.nixVersions.latest; # Versions.latest;
    # pin the registry to avoid downloading and evaling a new nixpkgs version every time
    registry = lib.mapAttrs (_: v: { flake = v; }) inputs;

    # set the path for channels compat
    nixPath = lib.mapAttrsToList (key: _: "${key}=flake:${key}") config.nix.registry;

    channel.enable = false;

    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      # Whether to accept nix configuration from a flake without prompting.
      accept-flake-config = true;
      cores = 0;
      max-jobs = "auto";
      connect-timeout = 5;
      http-connections = 0;
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
      flake-registry = "/etc/nix/registry.json";
      keep-derivations = true;
      keep-outputs = true;
      fallback = true;
      warn-dirty = false;
      nix-path = [ "nixpkgs=${pkgs.path}" ]; # FIXME https://discourse.nixos.org/t/24-05-add-flake-to-nix-path/46310/9
    };
    gc = {
      automatic = false; # because i am using nh.clean
      dates = "weekly";
      options = "--delete-older-than 1w";
    };
  };
}
