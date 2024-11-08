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
        auto-optimise-store = true;
        builders-use-substitutes = true;
        allowed-users = [
          "root"
        ];
        trusted-users = [
          "root"
        ];
        system-features = [
          "nixos-test"
          "kvm"
          "recursive-nix"
          "big-parallel"
        ];
        flake-registry = "/etc/nix/registry.json";
        nix-path = [ "nixpkgs=${pkgs.path}" ]; # FIXME https://discourse.nixos.org/t/24-05-add-flake-to-nix-path/46310/9
      };
      gc = {
        automatic = true;
        dates = "weekly";
        options = "--delete-older-than 1w";
      };
    };
}
