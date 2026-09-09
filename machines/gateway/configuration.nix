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

  # public sshd only feeds crowdsec ssh-bf; reach sshd via netbird (wt0 is
  # trusted), wireguard, yggdrasil, or p2p-ssh-iroh (loopback)
  services.openssh.openFirewall = false;
  networking.firewall.interfaces = {
    wireguard.allowedTCPPorts = [ 22 ];
    ygg.allowedTCPPorts = [ 22 ];
  };

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
