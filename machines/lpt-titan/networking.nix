{ flake-self, ... }:
{
  networking.networkmanager.ensureProfiles.profiles."home" = {
    ipv4 = {
      method = "manual";
      address1 = "${flake-self.hosts.lpt-titan.lan}/24,192.168.10.1";
      dns = "192.168.10.1;";
    };
    ipv6.method = "auto";
  };
}
