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
    extraHosts = ''
      192.168.178.91 argocd.space prometheus.space grafana.space thanos.space
    '';
  };
  services = {
    openssh = {
      enable = true;
      settings.UseDns = true;
    };
    resolved.enable = true;
  };
  #systemd.services.NetworkManager-wait-online.enable = false;
}
