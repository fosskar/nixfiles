{
  flake.modules.nixos.matrix =
    {
      flake-self,
      pkgs,
      ...
    }:
    let
      serviceName = "cinny";
      localHost = "${serviceName}.${flake-self.domains.local}";
      cinny = pkgs.cinny.override {
        conf = {
          defaultHomeserver = 0;
          # server_name, not the delegated host; well-known routes clients
          homeserverList = [ "fosskar.de" ];
          allowCustomHomeservers = false;
        };
      };
    in
    {
      services.homepage-dashboard.services = [
        {
          "communication" = [
            {
              "Cinny" = {
                href = "https://${localHost}";
                icon = "sh-cinny";
                siteMonitor = "https://${localHost}";
              };
            }
          ];
        }
      ];

      services.gatus.settings.endpoints = [
        {
          name = "Cinny";
          url = "https://${localHost}";
          enabled = true;
          alerts = [ { type = "email"; } ];
          interval = "5m";
          conditions = [ "[STATUS] == 200" ];
        }
      ];

      services.caddy.virtualHosts.${localHost}.extraConfig = ''
        root * ${cinny}
        file_server
        # spa: client-side routing needs fallback to index.html
        try_files {path} /index.html
      '';
    };
}
