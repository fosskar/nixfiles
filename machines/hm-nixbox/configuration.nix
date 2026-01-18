{ mylib, ... }:
{
  imports = [
    ../../modules/acme
    ../../modules/borgbackup
    ../../modules/nginx
    ../../modules/lldap
    ../../modules/authelia
    ../../modules/immich
    ../../modules/paperless
    ../../modules/vaultwarden
    ../../modules/zfs
    ../../modules/gpu
    ../../modules/cpu
    ../../modules/power
    ../../modules/persistence
    ../../modules/hd-idle
  ]
  ++ (mylib.scanPaths ./. {
    exclude = [
      "dashboards"
      "radicle.nix"
    ];
  });

  nixpkgs.hostPlatform = "x86_64-linux";

  clan.core.settings.machine-id.enable = true;

  nixfiles = {
    # persistence
    persistence = {
      enable = true;
      backend = "preservation";
      rollback = {
        type = "zfs";
        dataset = "znixos/root";
        poolImportService = "zfs-import-znixos.service";
      };
      directories = [
        "/var/log"
        "/var/cache"
        "/var/lib"
      ];
    };
    # backup
    borgbackup = {
      enable = true;
      folders = [
        "/tank/apps"
        "/tank/shares"
      ];
      useSnapshots = true;
      snapshotType = "zfs";
    };

    gpu.intel.enable = true;
    cpu.amd.enable = true;
    power.tuned = {
      enable = true;
      profile = "server-powersave";
    };
    authelia.publicDomain = "fosskar.eu";
  };

  # systemd-boot doesn't support mirroredBoots yet (nixpkgs#152155)
  boot = {
    kernelModules = [ "nct6775" ];
    loader = {
      systemd-boot.enable = false;
      grub = {
        enable = true;
        device = "nodev";
        mirroredBoots = [
          {
            devices = [ "nodev" ];
            path = "/boot";
          }
          {
            devices = [ "nodev" ];
            path = "/boot-fallback";
          }
        ];
      };
    };
    zfs.extraPools = [ "tank" ];
  };
}
