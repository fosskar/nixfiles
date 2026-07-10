{
  self,
  lib,
  nflib,
  pkgs,
  ...
}:
{
  imports = [
    self.modules.nixos.arrStack
    self.modules.nixos.caddy
    self.modules.nixos.matrix
    self.modules.nixos.opencrow
    self.modules.nixos.convertx
    self.modules.nixos.dawarich
    self.modules.nixos.opencloud
    self.modules.nixos.searxng
    self.modules.nixos.lldap
    self.modules.nixos.authelia
    self.modules.nixos.immich
    self.modules.nixos.llamaCpp
    self.modules.nixos.wyomingPiper
    self.modules.nixos.itTools
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
    self.modules.nixos.miniflux
    self.modules.nixos.wiki
    self.modules.nixos.vdirsyncer
  ]
  ++ (nflib.scanPaths ./. { });

  environment.systemPackages = [
    pkgs.ipmitool
  ];

  preservation.preserveAt."/persist".directories = [
    "/var/cache"
    "/var/lib"
  ];

  systemd.services =
    lib.genAttrs
      [
        "beszel-agent"
        "garage"
        "garage-layout-init"
        "garage-ui"
        "opencloud"
        "opencloud-permission-fixer"
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
