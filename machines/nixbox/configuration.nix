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
    self.modules.nixos.grub
    self.modules.nixos.intelGpu
    self.modules.nixos.amdCpu
    self.modules.nixos.tunedServerPowersave
    self.modules.nixos.preservation
    self.modules.nixos.hdIdle
    self.modules.nixos.docker
    self.modules.nixos.vert
    self.modules.nixos.homepage
    self.modules.nixos.ollama
    self.modules.nixos.ups
    self.modules.nixos.gatus
    self.modules.nixos.ntfy
    self.modules.nixos.garage
    self.modules.nixos.miniflux
    self.modules.nixos.wiki
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

  preservation = {
    rollback = {
      type = "zfs";
      dataset = "znixos/root";
      poolImportService = "zfs-import-znixos.service";
    };
    preserveAt."/persist".directories = [
      "/var/cache"
      "/var/lib"
    ];
  };

  services.garage.settings.data_dir = [
    {
      path = "/tank/apps/garage";
      capacity = "100G";
    }
  ];

  systemd.services.beszel-agent.unitConfig.RequiresMountsFor = [ "/tank" ];

  boot = {
    kernelModules = [
      "nct6775"
      "kvm-amd"
    ];
    loader = {
      grub = {
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
