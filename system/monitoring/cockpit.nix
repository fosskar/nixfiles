{
  config,
  pkgs,
  input,
  ...
}: let
  cpkgs = pkgs.nur.repos.dukzcry;
in {
  services.cockpit = {
    enable = true;
    port = 9092;
    openFirewall = true;
    settings = {
      WebService = {
        AllowUnencrypted = true;
      };
    };
  };
  # Nginx reverses proxy
  services.nginx = {
    enable = true;
    upstreams = {
      "cockpit" = {
        servers = {
          "127.0.0.1:${toString config.services.cockpit.port}" = {};
        };
      };
    };
    virtualHosts."cockpit.space" = {
      locations."/" = {
        proxyPass = "http://cockpit";
        proxyWebsockets = true;
      };
      listen = [
        {
          addr = "192.168.178.91";
          port = 80;
        }
      ];
    };
  };
  security.pam.services.cockpit = {};

  environment.systemPackages = with pkgs; with cpkgs; [cockpit-machines libvirt-dbus];

  systemd.sockets.cockpit.listenStreams = ["" "${toString config.services.cockpit.port}"];
  programs.virt-manager.enable = true;
}
