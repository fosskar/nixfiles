{
  flake.modules.nixos.base =
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
            "fetch-closure"
          ]
          ++ lib.optionals (lib.versionAtLeast (lib.versions.majorMinor config.nix.package.version) "2.29") [
            "blake3-hashes"
          ];

          allowed-users = lib.mkDefault [
            "root"
            "@wheel"
          ];

          flake-registry = lib.mkDefault "/etc/nix/registry.json";

          download-buffer-size = lib.mkDefault (256 * 1024 * 1024); # 256 MB

          # for direnv garbage-collection roots (keep-derivations already
          # defaults to true in nix itself)
          keep-outputs = lib.mkDefault true;

          warn-dirty = lib.mkDefault false;

          # avoid disk full
          max-free = lib.mkDefault (3000 * 1024 * 1024);
          min-free = lib.mkDefault (512 * 1024 * 1024);

          builders-use-substitutes = lib.mkDefault true;

          # zfs already provides transactional consistency, skip redundant fsync
          fsync-metadata = lib.mkDefault ((config.fileSystems."/".fsType or "") != "zfs");
        };

        # disable if nh.clean is enabled (it handles gc instead)
        gc = {
          automatic = lib.mkDefault (!(config.programs.nh.clean.enable or false));
          options = lib.mkDefault "--delete-older-than 15d";
        };
        # batch dedup via nix-optimise.timer instead of write-time
        # auto-optimise-store (per-build overhead, EMLINK noise on btrfs)
        optimise = {
          automatic = lib.mkDefault true;
          dates = lib.mkDefault [ "12:00" ];
        };
      };

      # weekly cleanup of stale gcroots/temproots not covered by nix.gc/nh clean
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
    };
}
