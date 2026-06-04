{
  self,
  lib,
  mylib,
  pkgs,
  ...
}:
{
  imports = [
    self.modules.nixos.arrStack
    self.modules.nixos.caddy
    self.modules.nixos.convertx
    self.modules.nixos.nextcloud
    self.modules.nixos.opencloud
    self.modules.nixos.searxng
    self.modules.nixos.nostrRelay
    self.modules.nixos.radicale
    self.modules.nixos.lldap
    self.modules.nixos.authelia
    self.modules.nixos.immich
    self.modules.nixos.llamaCpp
    self.modules.nixos.wyomingPiper
    self.modules.nixos.itTools
    self.modules.nixos.paperless
    self.modules.nixos.paperlessSamba
    self.modules.nixos.paperlessNextcloud
    self.modules.nixos.papra
    self.modules.nixos.vaultwarden
    self.modules.nixos.stirlingPdf
    self.modules.nixos.grub
    self.modules.nixos.nvidiaGpu
    self.modules.nixos.amdCpu
    self.modules.nixos.tunedServerPowersave
    self.modules.nixos.hdIdle
    self.modules.nixos.podman
    self.modules.nixos.homepage
    self.modules.nixos.smtp
    self.modules.nixos.gatus
    self.modules.nixos.msmtp
    self.modules.nixos.systemdEmailAlerts
    self.modules.nixos.garage
    self.modules.nixos.miniflux
    self.modules.nixos.wiki
  ]
  ++ (mylib.scanPaths ./. { });

  environment.systemPackages = [
    pkgs.ipmitool
  ];

  preservation.preserveAt."/persist".directories = [
    "/var/cache"
    "/var/lib"
  ];

  services.garage.settings.data_dir = [
    {
      path = "/tank/apps/garage";
      capacity = "100G";
    }
  ];

  systemd.services =
    lib.genAttrs
      [
        "beszel-agent"
        "garage"
        "garage-layout-init"
        "garage-webui"
        "nextcloud-cron"
        "nextcloud-notify_push"
        "nextcloud-notify_push_setup"
        "nextcloud-oidc-bootstrap"
        "nextcloud-setup"
        "nextcloud-update-db"
        "opencloud"
        "opencloud-permission-fixer"
        "papra"
        "paperless-consumer"
        "paperless-scheduler"
        "paperless-task-queue"
        "paperless-web"
        "phpfpm-nextcloud"
      ]
      (_: {
        after = [ "zfs-mount.service" ];
        requires = [ "zfs-mount.service" ];
        unitConfig.RequiresMountsFor = [ "/tank" ];
      });

  boot.kernelModules = [
    "nct6775"
    "kvm-amd"
  ];
}
