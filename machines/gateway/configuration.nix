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

  # sshd is not reachable from the internet; reach it via netbird (wt0
  # bypasses this firewall), wireguard, yggdrasil, or p2p-ssh-iroh (loopback)
  services.openssh.openFirewall = false;
  networking.firewall.interfaces = {
    wireguard.allowedTCPPorts = [ 22 ];
    ygg.allowedTCPPorts = [ 22 ];
  };

  # netbird exit clients get the internet, not gateway's overlays or the
  # hetzner metadata service. mdns and yggdrasil multicast serve lan peers,
  # which this vps has none of
  networking.nftables.tables.gateway-edge = {
    family = "inet";
    content = ''
      chain input {
        type filter hook input priority filter - 1; policy accept;
        iifname "eth0" udp dport { 5353, 9001 } drop
      }
      chain forward {
        type filter hook forward priority filter - 1; policy accept;
        iifname "wt0" oifname { "ygg", "wireguard" } drop
        iifname "wt0" ip daddr 169.254.0.0/16 drop
      }
    '';
  };

  # the daemon's 0666 socket lets any local uid run unprivileged rpcs such as
  # `netbird down`; only root uses it here
  systemd.services.netbird.serviceConfig.RuntimeDirectoryMode = "0750";

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
