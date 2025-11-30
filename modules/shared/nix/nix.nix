{
  lib,
  config,
  pkgs,
  ...
}:
{
  nix = {
    package = pkgs.nixVersions.latest; # nixVersions.latest, lix

    nixPath = [ "nixpkgs=flake:nixpkgs" ];

    channel.enable = lib.mkDefault false;

    settings = {
      connect-timeout = lib.mkDefault 5;
      download-buffer-size = lib.mkDefault (256 * 1024 * 1024); # 256 MB to handle large deployments
      fallback = true;

      # for direnv garbage-collection roots
      keep-derivations = true;
      keep-outputs = true;

      experimental-features = [
        "nix-command"
        "flakes"
      ]
      ++ lib.optional (lib.versionOlder (lib.versions.majorMinor config.nix.package.version) "2.22") "repl-flake";

      log-lines = lib.mkDefault 25;
      max-free = lib.mkDefault (3000 * 1024 * 1024);
      min-free = lib.mkDefault (512 * 1024 * 1024);

      builders-use-substitutes = true;

      trusted-users = [
        "root"
        "@wheel"
      ];

      # dont warn me that my git tree is dirty
      warn-dirty = false;
    };
    optimise.automatic = lib.mkDefault (!config.boot.isContainer);
  };
}
