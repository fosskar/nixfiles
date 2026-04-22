{
  self,
  mylib,
  pkgs,
  ...
}:
{
  imports = [
    self.modules.nixos.arrStack
    self.modules.nixos.caddy
    self.modules.nixos.borgbackup
    self.modules.nixos.nextcloud
    self.modules.nixos.lldap
    self.modules.nixos.authelia
    self.modules.nixos.immich
    self.modules.nixos.itTools
    self.modules.nixos.paperless
    self.modules.nixos.paperlessSamba
    self.modules.nixos.vaultwarden
    self.modules.nixos.stirlingPdf
    self.modules.nixos.zfs
    self.modules.nixos.intelGpu
    self.modules.nixos.amdCpu
    self.modules.nixos.tuned
    self.modules.nixos.preservation
    self.modules.nixos.hdIdle
    self.modules.nixos.docker
    self.modules.nixos.vert
    self.modules.nixos.homepage
    self.modules.nixos.gatus
    self.modules.nixos.ntfy
    self.modules.nixos.garage
    self.modules.nixos.miniflux
  ]
  ++ (mylib.scanPaths ./. {
    exclude = [
      "dashboards"
    ];
  });

  environment = {
    systemPackages = [
      pkgs.ipmitool
    ];
  };

  nixpkgs.hostPlatform = "x86_64-linux";

  clan.core.settings.machine-id.enable = true;

  nixfiles = {
    preservation = {
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

    borgbackup = {
      folders = [
        "/tank/apps"
        "/tank/backup"
        "/tank/shares"
      ];
      useSnapshots = true;
      snapshotType = "zfs";
    };

    tuned = {
      profile = "server-powersave";
    };

    authelia.publicDomain = "fosskar.eu";
    arrStack.authelia.enable = true;

    garage.dataDir = "/tank/apps/garage";

    beszelAgent = {
      sensors = "-nct6798_cputin,-nct6798_auxtin0,-nct6798_auxtin2,-nct6798_auxtin4";
      filesystem = "/persist";
      extraFilesystems = "/__Root,/nix__Nix,/boot__Boot,/boot-fallback__BootFallback,/tank__Tank,/tank/apps__Apps,/tank/media__Media,/tank/shares__Shares,/tank/backup__Backup";
    };
  };

  services.beszel.agent.environment.SMART_DEVICES =
    "/dev/nvme0,/dev/nvme1,/dev/sda,/dev/sdb,/dev/sdc,/dev/sdd,/dev/sde,/dev/sdf,/dev/sdg";
  systemd.services.beszel-agent.unitConfig.RequiresMountsFor = [ "/tank" ];

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
