{ pkgs, ... }:
{
  networking = {
    hostName = "hm-nixbox";
    hostId = "25e85037"; # zfs requires unique hostId

    useDHCP = false;
    defaultGateway = {
      address = "192.168.10.1";
      interface = "enp36s0f0np0";
    };
    nameservers = [ "192.168.10.1" ];

    interfaces.enp36s0f0np0.ipv4.addresses = [
      {
        address = "192.168.10.80";
        prefixLength = 24;
      }
    ];

    firewall.allowedTCPPorts = [
      80
      443
      5930
    ];
  };

  # disable resolved mdns (avahi handles it for samba/apple discovery)
  services.resolved.settings.Resolve.MulticastDNS = "no";

  # disable WoL on all ethernet interfaces
  systemd.network.links."10-disable-wol" = {
    matchConfig.OriginalName = "en*";
    linkConfig.WakeOnLan = "off";
  };

  # udev rules for network interfaces
  services.udev.extraRules = ''
    # increase ring buffer to reduce packet drops on 10G NIC
    ACTION=="add", SUBSYSTEM=="net", KERNEL=="enp36s0f0np0", RUN+="${pkgs.ethtool}/bin/ethtool -G $name rx 2047 tx 2047"
    # enable runtime power management for ethernet devices
    ACTION=="add", SUBSYSTEM=="net", KERNEL=="en*", RUN+="/bin/sh -c 'echo auto > /sys/class/net/%k/device/power/control'"
  '';
}
