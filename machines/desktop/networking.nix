{ flake-self, ... }:
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
        address1 = "${flake-self.hosts.desktop.lan}/24,${flake-self.router.lan}";
        dns = "${flake-self.router.lan};";
      };
      ipv6.method = "auto";
    };
  };
}
