{ pkgs, ... }:
{
  networking = {
    hostName = "nixbox";
    hostId = "25e85037"; # zfs requires unique hostId

    useDHCP = false;
    defaultGateway = {
      address = "192.168.10.1";
      interface = "bond0";
    };
    nameservers = [ "192.168.10.1" ];

    bonds.bond0 = {
      interfaces = [
        "enp36s0f0np0"
        "enp36s0f1np1"
      ];
      driverOptions = {
        mode = "active-backup";
        miimon = "100";
      };
    };

    interfaces.bond0 = {
      useDHCP = false;
      ipv4.addresses = [
        {
          address = "192.168.10.200";
          prefixLength = 24;
        }
      ];
    };
  };

  systemd.network.networks = {
    # clan sets multicastdns on these defaults without a match section.
    "99-ethernet-default-dhcp".enable = false;
    "99-wireless-client-dhcp".enable = false;
  };

  # disable WoL on all ethernet interfaces
  systemd.network.links."10-disable-wol" = {
    matchConfig.OriginalName = "en*";
    linkConfig.WakeOnLan = "off";
  };

  # udev rules for network interfaces
  services.udev.extraRules = ''
    # increase ring buffer to reduce packet drops on 10G NIC
    ACTION=="add", SUBSYSTEM=="net", KERNEL=="enp36s0f0np0", RUN+="${pkgs.ethtool}/bin/ethtool -G $name rx 2047 tx 2047"
    ACTION=="add", SUBSYSTEM=="net", KERNEL=="enp36s0f1np1", RUN+="${pkgs.ethtool}/bin/ethtool -G $name rx 2047 tx 2047"
    # enable runtime power management for ethernet devices
    ACTION=="add", SUBSYSTEM=="net", KERNEL=="en*", RUN+="/bin/sh -c 'echo auto > /sys/class/net/%k/device/power/control'"
  '';
}
