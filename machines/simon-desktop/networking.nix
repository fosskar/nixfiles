{
  networking = {
    networkmanager.ensureProfiles.profiles."lan" = {
      connection = {
        id = "lan";
        type = "ethernet";
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
