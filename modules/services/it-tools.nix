{
  flake.modules.nixos.itTools =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      acmeDomain = "nx3.eu";
      serviceDomain = "tools.${acmeDomain}";
    in
    {
      # --- homepage ---
      services.homepage-dashboard.serviceGroups."Tools" =
        lib.mkIf config.services.homepage-dashboard.enable
          [
            {
              "IT Tools" = {
                href = "https://${serviceDomain}";
                icon = "it-tools.svg";
                siteMonitor = "https://${serviceDomain}";
              };
            }
          ];

      # --- gatus ---
      services.gatus.settings.endpoints = lib.mkIf config.services.gatus.enable [
        {
          name = "IT Tools";
          url = "https://${serviceDomain}";
          group = "Tools";
          enabled = true;
          interval = "5m";
          conditions = [ "[STATUS] == 200" ];
          alerts = [ { type = "ntfy"; } ];
        }
      ];

      # --- caddy ---
      services.caddy.virtualHosts."tools.nx3.eu".extraConfig = ''
        root * ${pkgs.it-tools}/lib
        file_server
        try_files {path} {path}.html {path}/ =404
      '';
    };
}
