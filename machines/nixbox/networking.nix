_: {
  networking = {
    hostId = "25e85037"; # zfs requires unique hostId

    useDHCP = false;
    defaultGateway = {
      address = "192.168.20.1";
      interface = "bond0";
    };
    nameservers = [ "192.168.20.1" ];

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
          address = "192.168.20.200";
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
}
