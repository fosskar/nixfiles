{ flake-self, ... }:
{
  networking.networkmanager.ensureProfiles.profiles."home" = {
    ipv4 = {
      method = "manual";
      address1 = "${flake-self.hosts.lpt-titan.lan}/24,${flake-self.router.lan}";
      dns = "${flake-self.router.lan};";
    };
    ipv6.method = "auto";
  };
}
