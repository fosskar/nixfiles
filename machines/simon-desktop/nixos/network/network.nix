_: {
  # machine-specific networking - desktop module handles systemd service settings
  networking = {
    hostName = "simon-desktop";
    useNetworkd = true;
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
