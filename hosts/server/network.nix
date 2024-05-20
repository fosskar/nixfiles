_: {
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
