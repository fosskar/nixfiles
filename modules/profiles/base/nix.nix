{
  lib,
  config,
  pkgs,
  inputs,
  ...
}:
{
  # srvos sets: daemonCPUSchedPolicy, daemonIOSchedClass, daemonIOSchedPriority,
  # trusted-users, optimise.automatic, nix-daemon OOMScoreAdjust

  nix = {
    package = lib.mkDefault pkgs.nixVersions.latest;

    nixPath = [ "nixpkgs=${inputs.nixpkgs}" ];

    channel.enable = lib.mkDefault false;

    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];

      accept-flake-config = lib.mkDefault false;

      allowed-users = lib.mkDefault [
        "root"
        "@wheel"
      ];

      flake-registry = lib.mkDefault "/etc/nix/registry.json";

      download-buffer-size = lib.mkDefault (256 * 1024 * 1024); # 256 MB

      # for direnv garbage-collection roots
      keep-derivations = lib.mkDefault true;
      keep-outputs = lib.mkDefault true;

      warn-dirty = lib.mkDefault false;

      auto-optimise-store = lib.mkDefault true;

      log-lines = lib.mkDefault 25;

      # avoid disk full
      max-free = lib.mkDefault (3000 * 1024 * 1024);
      min-free = lib.mkDefault (512 * 1024 * 1024);

      builders-use-substitutes = lib.mkDefault true;
    };

    # disable if nh.clean is enabled (it handles gc instead)
    gc.automatic = lib.mkDefault (!(config.programs.nh.clean.enable or false));
  };
}
