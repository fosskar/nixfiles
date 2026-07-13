{
  flake.modules.nixos.matrix =
    {
      flake-self,
      pkgs,
      ...
    }:
    let
      serviceName = "element";
      localHost = "${serviceName}.${flake-self.domains.local}";
      element = pkgs.element-web.override {
        conf = {
          default_server_config."m.homeserver" = {
            # server_name, not the delegated host; well-known routes clients
            server_name = "fosskar.de";
            base_url = "https://matrix.${flake-self.domains.public}";
          };
        };
      };
    in
    {
      services.homepage-dashboard.services = [
        {
          "communication" = [
            {
              "Element" = {
                href = "https://${localHost}";
                icon = "sh-element";
                siteMonitor = "https://${localHost}";
              };
            }
          ];
        }
      ];

      services.gatus.settings.endpoints = [
        {
          name = "Element";
          url = "https://${localHost}";
          enabled = true;
          alerts = [ { type = "email"; } ];
          interval = "5m";
          conditions = [ "[STATUS] == 200" ];
        }
      ];

      services.caddy.virtualHosts.${localHost}.extraConfig = ''
        root * ${element}
        file_server
        # spa: client-side routing needs fallback to index.html
        try_files {path} /index.html
      '';
    };
}
