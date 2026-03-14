{
  mylib,
  pkgs,
  ...
}:
{
  imports = [
    ../../modules/arr-stack
    ../../modules/caddy
    ../../modules/borgbackup
    ../../modules/opencloud
    ../../modules/nextcloud
    ../../modules/lldap
    ../../modules/authelia
    ../../modules/immich
    ../../modules/paperless
    ../../modules/vaultwarden
    ../../modules/stirling-pdf
    ../../modules/zfs
    ../../modules/gpu
    ../../modules/cpu
    ../../modules/power
    ../../modules/persistence
    ../../modules/hd-idle
    ../../modules/virtualization
    ../../modules/vert
    ../../modules/homepage
    ../../modules/gatus
    ../../modules/ntfy
    ../../modules/garage
    ../../modules/miniflux
  ]
  ++ (mylib.scanPaths ./. {
    exclude = [
      "dashboards"
    ];
  });

  # HP printer scan-to-network-folder via samba → paperless
  nixfiles.paperless.samba.enable = true;

  ## INFO: this i needed when i want to remove a conflicting user or group. userborn never deleted removes user or groups.
  #services.userborn.enable = lib.mkForce false;

  environment = {
    systemPackages = [
      pkgs.ipmitool
    ];
  };

  nixpkgs.hostPlatform = "x86_64-linux";

  clan.core.settings.machine-id.enable = true;

  nixfiles = {
    # persistence
    persistence = {
      enable = true;
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
        "/tank/backup"
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
    arr-stack.authelia.enable = true;

    virtualization.docker.enable = true;

    garage.dataDir = "/tank/apps/garage";
  };

  # systemd-boot doesn't support mirroredBoots yet (nixpkgs#152155)
  boot = {
    kernelModules = [
      "nct6775"
      "kvm-amd"
    ];
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
