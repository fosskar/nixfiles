{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [ networkmanagerapplet ];

  networking = {
    wireless = {
      enable = false;
      iwd = {
        enable = true;
        settings = {
          IPv6 = {
            Enabled = false;
          };
          Settings = {
            AutoConnect = false;
          };
        };
      };
    };
    networkmanager = {
      enable = true;
      wifi.backend = "iwd";
      dns = "systemd-resolved";
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
    nameservers = [
      # mullevad
      "194.242.2.2"
      "2a07:e340::2"

      # quad9, said to be the best
      # shares *less* data
      "9.9.9.9"
      "149.112.112.112"
      "2620:fe::fe"
      "2620:fe::9"
    ];
  };
}
