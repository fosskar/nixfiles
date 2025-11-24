{ lib, config, ... }:
{
  nix = {
    channel.enable = lib.mkDefault false;

    settings = {
      connect-timeout = lib.mkDefault 5;
      download-buffer-size = lib.mkDefault (256 * 1024 * 1024); # 256 MB to handle large deployments
      fallback = true;

      experimental-features = [
        "nix-command"
        "flakes"
      ]
      ++ lib.optional (lib.versionOlder (lib.versions.majorMinor config.nix.package.version) "2.22") "repl-flake";

      log-lines = lib.mkDefault 25;
      max-free = lib.mkDefault (3000 * 1024 * 1024);
      min-free = lib.mkDefault (512 * 1024 * 1024);

      builders-use-substitutes = true;

      trusted-users = [ "@wheel" ];
    };
    optimise.automatic = lib.mkDefault (!config.boot.isContainer);
  };
}
