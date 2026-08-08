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
    self.modules.nixos.grub
    self.modules.nixos.tunedVirtualGuest
  ]
  ++ (nflib.scanPaths ./. { });

  # srvos.hardware-hetzner-cloud sets: qemuGuest, grub /dev/sda, networkd
  # srvos.server sets: emergency mode suppression

  # don't retain .drvs on this server (keep-outputs already defaults off)
  nix.settings.keep-derivations = false;

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
