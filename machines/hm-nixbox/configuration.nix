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
    ../../modules/it-tools
    ../../modules/paperless
    ../../modules/vaultwarden
    ../../modules/stirling-pdf
    ../../modules/filesystems/zfs.nix
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

    beszel.agent = {
      sensors = "-nct6798_cputin,-nct6798_auxtin0,-nct6798_auxtin2,-nct6798_auxtin4";
      filesystem = "/persist";
      extraFilesystems = "/__Root,/nix__Nix,/boot__Boot,/boot-fallback__BootFallback,/tank__Tank,/tank/apps__Apps,/tank/media__Media,/tank/shares__Shares,/tank/backup__Backup";
    };
  };

  # machine-specific beszel config
  services.beszel.agent.environment.SMART_DEVICES =
    "/dev/nvme0,/dev/nvme1,/dev/sda,/dev/sdb,/dev/sdc,/dev/sdd,/dev/sde,/dev/sdf,/dev/sdg";
  systemd.services.beszel-agent.unitConfig.RequiresMountsFor = [ "/tank" ];

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
