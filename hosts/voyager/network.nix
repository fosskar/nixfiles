{
  config,
  pkgs,
  lib,
  ...
}: {
  networking = {
    hostName = "nixos-server";
    #networkmanager.enable = true;
    wireless.enable = true;
    firewall = {
      enable = true;
      allowPing = true;
      logRefusedConnections = false;
      allowedTCPPorts = [22 53 80 443];
      allowedUDPPorts = [53];
    };
    useDHCP = false;
    nameservers = ["127.0.0.1"];
    defaultGateway = "192.168.178.1";
    defaultGateway6 = {
      address = "fe80::1eed:6fff:fef1:8f6f";
      interface = "wlo1";
    };
    #extraHosts = ''
    #'';
    interfaces.wlo1 = {
      ipv4 = {
        addresses = [
          {
            address = "192.168.178.91";
            prefixLength = 24;
          }
        ];
      };
      ipv6 = {
        addresses = [
          {
            address = "2a04:4540:641c:2300:b2dc:efff:fe81:46f6";
            prefixLength = 64;
          }
        ];
      };
    };
  };

  ## FIXME add initrd ssh host key
  #boot.initrd.network = {
  #  enable = true;
  #  ssh = {
  #    enable = true;
  #    port = 22;
  #    #hostKeys = [
  #    #  #FIXME this has to be manually uploaded during installation...
  #    #  # scp /tmp/initrd-ssh-key root@95.217.199.121:/mnt/var/lib/initrd-ssh-key
  #    #  "/var/lib/initrd-ssh-key"
  #    #];
  #  };
  #};

  systemd = {
    services = {
      NetworkManager-wait-online.enable = false;
      systemd-networkd.stopIfChanged = false;
      systemd-resolved.stopIfChanged = false;
    };
    network.wait-online.enable = false;
  };

  services.fail2ban.enable = true;

  services.tailscale = {
    enable = true;
    #useRoutingFeatures = "server";
  };
}
