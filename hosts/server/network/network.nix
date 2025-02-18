{ lib, ... }:
{
  networking = {
    useNetworkd = lib.mkDefault true;
    useDHCP = false;
    interfaces."eth0" = {
      ipv4.addresses = [
        {
          address = "5.9.80.138";
          prefixLength = 24;
        }
      ];
      ipv6.addresses = [
        {
          address = "2a01:4f8:162:183::1";
          prefixLength = 64;
        }
      ];
    };
    defaultGateway = {
      address = "5.9.80.129";
      interface = "eth0";
    };
    defaultGateway6 = {
      address = "fe80::1";
      interface = "eth0";
    };
    nameservers = [ "8.8.8.8" ];
    timeServers = [
      "ntp1.hetzner.de"
      "ntp2.hetzner.com"
      "ntp3.hetzner.de"
    ];
  };
  systemd = {
    network.networks."10-uplink" = {
      matchConfig.Name = lib.mkDefault "en* eth0";
      networkConfig = {
        DHCP = "ipv4";
        # hetzner requires static ipv6 addresses
        Gateway = "fe80::1";
        IPv6AcceptRA = "no";
      };
    };
    services = {
      NetworkManager-wait-online.enable = false;
      systemd-networkd.stopIfChanged = false;
      systemd-resolved.stopIfChanged = false;
    };
    network.wait-online.enable = false;
  };
}
