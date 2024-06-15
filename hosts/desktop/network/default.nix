_: {
  networking = {
    wireless.enable = false; #disable wpa-supplicant. nmcli usable for wifi in networkmanager
    nameservers = ["9.9.9.9#dns.quad9.net"];
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

    hosts = {
      "192.168.178.91" = [
        "argocd.space"
        "prometheus.space"
        "grafana.space"
        "vaultwarden.space"
        "home.space"
      ];
    };
  };

  services = {
    openssh = {
      enable = true;
      settings.UseDns = true;
    };

    resolved = {
      enable = true;
      dnsovertls = "opportunistic";
    };
  };
  #systemd.services.NetworkManager-wait-online.enable = false;
}
