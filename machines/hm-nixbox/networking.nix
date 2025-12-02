{ ... }:
{
  networking = {
    hostName = "hm-nixbox";
    # zfs hostId - required, unique per machine
    hostId = "25e85037";
    useDHCP = false;
  };

  # native systemd-networkd config for static ip
  systemd.network.networks."10-lan" = {
    matchConfig.Name = "enp36s0f0np0";
    address = [
      "192.168.10.80/24"
    ];
    routes = [
      { Gateway = "192.168.10.1"; }
    ];
    linkConfig.RequiredForOnline = "routable";
  };
}
