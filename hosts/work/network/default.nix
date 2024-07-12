_: {
  networking = {
    hostName = "nixos-work";
    wireless.enable = false; # disable wpa-supplicant. nmcli usable for wifi in networkmanager
    nameservers = [ ];
    networkmanager = {
      enable = true;
      dns = "systemd-resolved";
      wifi.powersave = true;
    };

    firewall = {
      enable = true;
    };
    nftables = {
      enable = true;
    };
  };

  services = {
    openssh = {
      enable = true;
      settings.UseDns = true;
    };

    resolved = {
      enable = true;
      dnssec = "allow-downgrade";
      dnsovertls = "opportunistic";
    };
  };
  #systemd.services.NetworkManager-wait-online.enable = false;
}
