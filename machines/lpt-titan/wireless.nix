_: {
  #environment.systemPackages = [ pkgs.iwgtk ];

  # enable wireless database, it helps with finding the right channels
  hardware.wirelessRegulatoryDatabase = true;

  networking = {
    wireless = {
      enable = false; # disable wpa-supplicant we use iwd
      iwd = {
        enable = false;
        settings = {
          #Rank.BandModifier5Ghz = 2.0;
          Scan.DisablePeriodicScan = true;
          Settings.AutoConnect = true;
          IPv6.Enabled = false;

          General = {
            AddressRandomization = "network";
            AddressRandomizationRange = "full";
            EnableNetworkConfiguration = true;
            RoamRetryInterval = 15;
          };

          Network = {
            EnableIPv6 = true;
            RoutePriorityOffset = 300;
            # NameResolvingService = "resolvconf";
          };
        };
      };
    };
  };
  #systemd = {
  #  user.services.iwgtk = {
  #    serviceConfig.ExecStart = "${lib.getExe pkgs.iwgtk} -i";
  #    wantedBy = [ "graphical-session.target" ];
  #    partOf = [ "graphical-session.target" ];
  #  };
  #};
  #systemd.services.NetworkManager-wait-online.enable = false;
}
