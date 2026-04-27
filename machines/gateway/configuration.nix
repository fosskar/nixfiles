{
  self,
  lib,
  mylib,
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
  ++ (mylib.scanPaths ./. { });

  # srvos.hardware-hetzner-cloud sets: qemuGuest, grub /dev/sda, networkd
  # srvos.server sets: emergency mode suppression

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
