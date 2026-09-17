{
  flake.modules.nixos.base =
    {
      lib,
      config,
      pkgs,
      inputs,
      self,
      ...
    }:
    {
      # srvos sets: trusted-users, optimise.automatic, nix-daemon OOMScoreAdjust

      srvos.flake = self;

      nix = {
        package = lib.mkDefault pkgs.nixVersions.stable;

        # de-prioritise builds so they don't starve running services
        daemonCPUSchedPolicy = lib.mkDefault "batch";
        daemonIOSchedClass = lib.mkDefault "idle";
        daemonIOSchedPriority = lib.mkDefault 7;

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

          warn-dirty = lib.mkDefault false;

          keep-going = lib.mkDefault true;

          builders-use-substitutes = lib.mkDefault true;

          # zfs already provides transactional consistency, skip redundant fsync
          fsync-metadata = lib.mkDefault ((config.fileSystems."/".fsType or "") != "zfs");
        };

        # disable if nh.clean is enabled (it handles gc instead)
        gc = {
          automatic = lib.mkDefault (!(config.programs.nh.clean.enable or false));
          options = lib.mkDefault "--delete-older-than 15d";
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
