{
  flake.modules.nixos.bentopdf =
    { flake-self, ... }:
    let
      serviceName = "bento";
      localHost = "${serviceName}.${flake-self.domains.local}";
    in
    {
      services.bentopdf = {
        enable = true;
        domain = localHost;
        caddy.enable = true;
      };

      services.homepage-dashboard.services = [
        {
          "tools" = [
            {
              "BentoPDF" = {
                href = "https://${localHost}";
                icon = "sh-bentopdf";
                siteMonitor = "https://${localHost}";
              };
            }
          ];
        }
      ];

      services.gatus.settings.endpoints = [
        {
          name = "BentoPDF";
          url = "https://${localHost}";
          enabled = true;
          alerts = [ { type = "email"; } ];
          interval = "5m";
          conditions = [ "[STATUS] == 200" ];
        }
      ];
    };
}
