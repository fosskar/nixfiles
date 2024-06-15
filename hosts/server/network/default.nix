_: {
  networking = {
    hostName = "nixos-server";
    #networkmanager.enable = true;
    wireless.enable = true;
    firewall = {
      enable = true;
      allowPing = true;
      logRefusedConnections = false;
      allowedTCPPorts = [22 53 80 443 6443];
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
}
