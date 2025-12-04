{ ... }:
{
  networking = {
    hostName = "hm-nixbox";
    # zfs hostId - required, unique per machine
    hostId = "25e85037";
    useDHCP = false;

    firewall.allowedTCPPorts = [
      80
      443
    ];
  };

  # native systemd-networkd for static ip
  systemd.network = {
    enable = true;
    networks."10-lan" = {
      matchConfig.Name = "enp36s0f0np0";
      address = [
        "192.168.10.80/24"
      ];
      routes = [
        {
          Gateway = "192.168.10.1";
        }
      ];
      networkConfig = {
        DNS = [ "192.168.10.1" ];
        # disable ipv6 completely on this interface
        IPv6AcceptRA = false;
        LinkLocalAddressing = "no";
        IPv6LinkLocalAddressGenerationMode = "none";
      };
      linkConfig.RequiredForOnline = "routable";
    };
  };
}
