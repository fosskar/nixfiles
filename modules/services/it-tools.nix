{
  flake.modules.nixos.itTools =
    {
      config,
      domains,
      lib,
      pkgs,
      ...
    }:
    let
      serviceName = "tools";
      localHost = "${serviceName}.${domains.local}";
    in
    {
      # --- homepage ---
      services.homepage-dashboard.serviceGroups."Tools" =
        lib.mkIf config.services.homepage-dashboard.enable
          [
            {
              "IT Tools" = {
                href = "https://${localHost}";
                icon = "it-tools.svg";
                siteMonitor = "https://${localHost}";
              };
            }
          ];

      # --- gatus ---
      services.gatus.settings.endpoints = lib.mkIf config.services.gatus.enable [
        {
          name = "IT Tools";
          url = "https://${localHost}";
          group = "Tools";
          enabled = true;
          interval = "5m";
          conditions = [ "[STATUS] == 200" ];
          alerts = [ { type = "ntfy"; } ];
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
