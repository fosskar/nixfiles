{ flake-self, ... }:
{
  # static lan nic below; facter would run dhcp on every other nic
  hardware.facter.detected.dhcp.enable = false;

  # i40e rx ring 512 -> 2048: builds saturate every cpu, softirq falls
  # behind and the nic counts rx_missed_errors. only the first matching
  # .link applies, so repeat 99-default.link's naming policies
  systemd.network.links."10-enp5s0f0np0" = {
    matchConfig.PermanentMACAddress = "38:05:25:30:7c:15";
    linkConfig = {
      NamePolicy = "keep kernel database onboard slot path";
      AlternativeNamesPolicy = "database onboard slot path mac";
      MACAddressPolicy = "persistent";
      RxBufferSize = 2048;
    };
  };

  networking = {
    useDHCP = false;
    nameservers = [ flake-self.router.srv ];
    defaultGateway = {
      address = flake-self.router.srv;
      interface = "enp5s0f0np0";
    };

    interfaces.enp5s0f0np0 = {
      useDHCP = false;
      ipv4.addresses = [
        {
          address = flake-self.hosts.nixworker.lan;
          prefixLength = 24;
        }
      ];
    };
  };
}
