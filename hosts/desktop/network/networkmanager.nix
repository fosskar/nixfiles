{ lib, pkgs, ... }:
{
  environment.systemPackages = with pkgs; [ networkmanagerapplet ];

  networking = {
    wireless.enable = false;
    networkmanager = {
      enable = true;
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
      # cloudflare, yuck
      # shares data
      "1.1.1.1"
      "1.0.0.1"
      "2606:4700:4700::1111"
      "2606:4700:4700::1001"

      # quad9, said to be the best
      # shares *less* data
      "9.9.9.9"
      "149.112.112.112"
      "2620:fe::fe"
      "2620:fe::9"
    ];
  };
}
