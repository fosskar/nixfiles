{
  flake.modules.nixos.itTools =
    {
      flake-self,
      pkgs,
      ...
    }:
    let
      serviceName = "tools";
      localHost = "${serviceName}.${flake-self.domains.local}";
    in
    {
      # --- homepage ---
      services.homepage-dashboard.services = [
        {
          "tools" = [
            {
              "IT Tools" = {
                href = "https://${localHost}";
                icon = "it-tools.svg";
                siteMonitor = "https://${localHost}";
              };
            }
          ];
        }
      ];

      # --- gatus ---
      services.gatus.settings.endpoints = [
        {
          name = "IT Tools";
          url = "https://${localHost}";
          enabled = true;
          alerts = [ { type = "email"; } ];
          interval = "5m";
          conditions = [ "[STATUS] == 200" ];
        }
      ];

      # --- caddy ---
      services.caddy.virtualHosts.${localHost}.extraConfig = ''
        root * ${pkgs.it-tools}/lib
        file_server
        try_files {path} {path}.html {path}/ =404
      '';
    };
}
