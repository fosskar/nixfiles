{
  self,
  nflib,
  pkgs,
  ...
}:
{
  imports = [
    self.modules.nixos.arrStack
    self.modules.nixos.caddy
    self.modules.nixos.matrix
    self.modules.nixos.convertx
    self.modules.nixos.dawarich
    self.modules.nixos.opencloud
    self.modules.nixos.mcp
    self.modules.nixos.searxng
    self.modules.nixos.lldap
    self.modules.nixos.authelia
    self.modules.nixos.nixbotOidc
    self.modules.nixos.immich
    self.modules.nixos.llamaCpp
    self.modules.nixos.vllm
    self.modules.nixos.itTools
    self.modules.nixos.vaultwarden
    self.modules.nixos.stirlingPdf
    self.modules.nixos.protomaps
    self.modules.nixos.opensoho
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
    self.modules.nixos.talosVm
    self.modules.nixos.kiwix
  ]
  ++ (nflib.scanPaths ./. { });

  services.systemdEmailAlerts.extraServices = [ "borgbackup-job-storagebox" ];

  environment.systemPackages = [
    pkgs.ipmitool
  ];

  boot.kernelModules = [
    "nct6775"
    "kvm-amd"
  ];
}
