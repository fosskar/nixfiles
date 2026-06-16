{
  self,
  lib,
  nflib,
  inputs,
  ...
}:
{
  imports = [
    inputs.srvos.nixosModules.hardware-hetzner-cloud
    self.modules.nixos.crowdsec
    self.modules.nixos.crowdsecTraefik
    self.modules.nixos.crowdsecClanWhitelist
    self.modules.nixos.grub
    self.modules.nixos.tunedVirtualGuest
    self.modules.nixos.traefik
    self.modules.nixos.traefikGeoblock
  ]
  ++ (nflib.scanPaths ./. { });

  # srvos.hardware-hetzner-cloud sets: qemuGuest, grub /dev/sda, networkd
  # srvos.server sets: emergency mode suppression

  # no dev shells on this server; don't retain build-time deps in the store
  nix.settings = {
    keep-derivations = false;
    keep-outputs = false;
  };

  topology.self = {
    icon = "devices.cloud-server";
    hardware.info = "hetzner vps";
    interfaces.wan = {
      addresses = [ "138.201.155.21" ];
      network = "internet";
    };
  };

  preservation.preserveAt."/persist".directories = [
    {
      directory = "/var/lib/private";
      mode = "0700";
    }
  ];

  services.cloud-init = {
    settings = {
      preserve_hostname = true;
      cloud_init_modules = lib.mkForce [
        "migrator"
        "seed_random"
        "bootcmd"
        "write-files"
        "growpart"
        "resizefs"
        "resolv_conf"
        "ca-certs"
        "rsyslog"
      ];
    };
  };
}
