{
  self,
  lib,
  mylib,
  ...
}:
{
  imports = [
    self.modules.nixos.btrfs
    self.modules.nixos.systemdBoot
    self.modules.nixos.tunedServerPowersave
    self.modules.nixos.preservation
    self.modules.nixos.opencrow
    self.modules.nixos.nostrRelay
  ]
  ++ (mylib.scanPaths ./. { });

  preservation = {
    rollback = {
      type = "btrfs";
      deviceLabel = "root";
    };
    preserveAt."/persist".directories = [ "/root" ];
  };

  boot.kernel.sysctl = {
    # crowbox has nftables, not iptables bridge filtering. avoid br_netfilter warning.
    "net.bridge.bridge-nf-call-iptables" = lib.mkForce null;

    # nixos emits these per-interface sysctls before the links exist.
    # keep ipv6/yggdrasil enabled; only suppress the early writes.
    "net.ipv4.conf.enp1s0.proxy_arp" = lib.mkForce null;
    "net.ipv4.conf.wlan0.proxy_arp" = lib.mkForce null;
    "net.ipv6.conf.enp1s0.use_tempaddr" = lib.mkForce null;
    "net.ipv6.conf.wlan0.use_tempaddr" = lib.mkForce null;
  };

  srvos.boot.consoles = [ "tty0" ];
}
