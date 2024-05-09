_: {
  networking = {
    wireless.enable = false; #disable wpa-supplicant. nmcli usable for wifi in networkmanager
    networkmanager = {
      enable = true;
      dns = "systemd-resolved";
      wifi.powersave = true;
    };
    firewall = {
      enable = true;
    };
  };
  services = {
    openssh.enable = true;
    resolved.enable = true;
  };
  #systemd.services.NetworkManager-wait-online.enable = false;
}
