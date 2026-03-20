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

      # zfs already provides transactional consistency, skip redundant fsync
      fsync-metadata = lib.mkDefault ((config.fileSystems."/".fsType or "") != "zfs");
    };

    # disable if nh.clean is enabled (it handles gc instead)
    gc.automatic = lib.mkDefault (!(config.programs.nh.clean.enable or false));
  };

  # --- gcroots cleanup ---
  # nh handles profile/generation gc, but stale automatic gcroots
  # (from nix-build, nix develop, etc.) and broken symlinks accumulate
  # separately. clean them weekly.
  systemd.timers.nix-cleanup-gcroots = {
    timerConfig = {
      OnCalendar = [ "weekly" ];
      Persistent = true;
    };
    wantedBy = [ "timers.target" ];
  };

  systemd.services.nix-cleanup-gcroots = {
    serviceConfig = {
      Type = "oneshot";
      ExecStart = [
        # delete automatic gcroots older than 30 days
        "${pkgs.findutils}/bin/find /nix/var/nix/gcroots/auto /nix/var/nix/gcroots/per-user -type l -mtime +30 -delete"
        # delete stale temproots (leftover from interrupted builds)
        "${pkgs.findutils}/bin/find /nix/var/nix/temproots -type f -mtime +10 -delete"
        # delete broken symlinks in gcroots
        "${pkgs.findutils}/bin/find /nix/var/nix/gcroots -xtype l -delete"
      ];
    };
  };
}
