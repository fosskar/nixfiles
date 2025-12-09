_: {
  networking = {
    hostName = "simon-desktop";
    networkmanager = {
      enable = true;
      wifi = {
        backend = "iwd";
        macAddress = "random";
        powersave = true;
        scanRandMacAddress = true;
      };
      dns = "systemd-resolved";
    };
  };
}
