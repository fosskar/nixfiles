{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
{
  nix = {
    package = pkgs.nix;
    # pin the registry to avoid downloading and evaling a new nixpkgs version every time
    registry = lib.mapAttrs (_: v: { flake = v; }) inputs;

    # set the path for channels compat
    nixPath = lib.mapAttrsToList (key: _: "${key}=flake:${key}") config.nix.registry;

    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
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
    };
    gc = {
      automatic = true;
      options = "--delete-older-than 1w";
    };
  };
  manual = {
    html.enable = false;
    json.enable = false;
    manpages.enable = false;
  };
}
