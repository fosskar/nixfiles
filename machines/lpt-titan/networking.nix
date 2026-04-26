{
  networking.networkmanager.ensureProfiles.profiles."home" = {
    ipv4 = {
      method = "manual";
      address1 = "192.168.10.150/24,192.168.10.1";
      dns = "192.168.10.1;";
    };
    ipv6.method = "auto";
  };
}
