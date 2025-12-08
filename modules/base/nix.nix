{
  lib,
  config,
  pkgs,
  ...
}:
{
  # clan sets: experimental-features, connect-timeout, log-lines, min-free, max-free, builders-use-substitutes
  nix = {
    package = pkgs.nixVersions.latest;

    nixPath = [ "nixpkgs=flake:nixpkgs" ];

    channel.enable = lib.mkDefault false;

    settings = {
      download-buffer-size = lib.mkDefault (256 * 1024 * 1024); # 256 MB for large deployments
      fallback = true;

      # for direnv garbage-collection roots
      keep-derivations = true;
      keep-outputs = true;

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
