{
  lib,
  config,
  pkgs,
  ...
}:
{
  # clan also sets: experimental-features, connect-timeout, log-lines, min-free, max-free, builders-use-substitutes
  nix = {
    package = lib.mkDefault pkgs.nixVersions.latest;

    nixPath = [ "nixpkgs=flake:nixpkgs" ];

    channel.enable = lib.mkDefault false;

    # lower priority for builds
    daemonCPUSchedPolicy = lib.mkDefault "batch";
    daemonIOSchedClass = lib.mkDefault "idle";
    daemonIOSchedPriority = lib.mkDefault 7;

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

      download-buffer-size = lib.mkDefault (256 * 1024 * 1024); # 256 MB for large deployments

      # for direnv garbage-collection roots
      keep-derivations = lib.mkDefault true;
      keep-outputs = lib.mkDefault true;

      trusted-users = [
        "root"
        "@wheel"
      ];

      # dont warn me that my git tree is dirty
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

    optimise.automatic = lib.mkDefault (!config.boot.isContainer);
  };

  # prefer killing builds over user sessions on OOM
  systemd.services.nix-daemon.serviceConfig.OOMScoreAdjust = lib.mkDefault 250;
}
