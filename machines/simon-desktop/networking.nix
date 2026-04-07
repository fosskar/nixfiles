{
  networking = {
    hostName = "simon-desktop";

    networkmanager.ensureProfiles.profiles.enp14s0 = {
      connection = {
        id = "enp14s0";
        type = "ethernet";
        interface-name = "enp14s0";
        autoconnect = true;
      };
      ipv4 = {
        method = "manual";
        address1 = "192.168.10.100/24,192.168.10.1";
        dns = "192.168.10.1;";
      };
      ipv6.method = "auto";
    };
  };
}
