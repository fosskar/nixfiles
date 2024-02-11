{
  config,
  pkgs,
  ...
}: {
  networking = {
    hostName = "nixos";
    wireless.enable = false; #disable wpa-supplicant. nmcli usable for wifi in networkmanager
    networkmanager = {
      enable = true;
      #dns = "systemd-resolved";
      #appendNameservers = ["192.168.178.91" "9.9.9.9"];
      #insertNameservers = ["192.168.178.91" "9.9.9.9"];
    };
    firewall = {
      enable = true;
      # allowedTCPPorts = [ ... ];
      # allowedUDPPorts = [ ... ];
    };
    nameservers = ["192.168.178.91"];
    #extraHosts = ''
    #'';
  };
  services.resolved = {
    enable = true;
    domains = ["space"];
    dnssec = "false";
  };

  #systemd.services.NetworkManager-wait-online.enable = false;

  services.tailscale = {
    enable = false;
    #useRoutingFeatures = "server";
  };
}
