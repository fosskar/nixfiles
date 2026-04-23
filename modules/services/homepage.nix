{
  flake.modules.nixos.homepage =
    { config, ... }:
    {
      services.homepage-dashboard = {
        enable = true;
        listenPort = 8082;
        openFirewall = false;
        allowedHosts = "home.nx3.eu";

        settings = {
          title = "home-lab dashboard";
          headerStyle = "underlined";
          useEqualheights = true;
          hideVersion = true;
          disableUpdateCheck = true;
          disableIndexing = true;
          statusStyle = "dot";
          cardBlur = "xl";
        };

        customJS = "";
      };

      services.caddy.virtualHosts."home.nx3.eu".extraConfig = ''
        reverse_proxy 127.0.0.1:${toString config.services.homepage-dashboard.listenPort}
      '';
    };
}
