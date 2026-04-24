{
  flake.modules.nixos.arrStack =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      acmeDomain = "nx3.eu";
      serviceDomain = "radarr.${acmeDomain}";
      bindAddress = "127.0.0.1";
      port = 7878;
      internalUrl = "http://${bindAddress}:${toString port}";
    in
    {
      config = {
        # --- service ---

        services.radarr = {
          enable = true;
          openFirewall = false;
          group = "media";
          settings.server.port = port;
        };

        # --- homepage ---

        services.homepage-dashboard.serviceGroups."Arr Stack" =
          lib.mkIf config.services.homepage-dashboard.enable
            [
              {
                "Radarr" = {
                  href = "https://${serviceDomain}";
                  icon = "radarr.svg";
                  siteMonitor = internalUrl;
                };
              }
            ];

        # --- gatus ---

        services.gatus.settings.endpoints = lib.mkIf config.services.gatus.enable [
          {
            name = "Radarr";
            url = internalUrl;
            group = "Arr Stack";
            enabled = true;
            interval = "5m";
            conditions = [ "[STATUS] == 200" ];
            alerts = [ { type = "ntfy"; } ];
          }
        ];

        # --- caddy ---

        services.caddy.virtualHosts."radarr.nx3.eu".extraConfig = ''
          ${lib.optionalString (config.services.authelia.instances.main.enable or false) "import authelia"}
          reverse_proxy 127.0.0.1:${toString port}
        '';

        # --- backup ---

        clan.core.state.radarr = {
          folders = [ "/var/backup/radarr" ];
          preBackupScript = ''
            export PATH=${
              lib.makeBinPath [
                pkgs.sqlite
                pkgs.coreutils
              ]
            }
            mkdir -p /var/backup/radarr
            sqlite3 /var/lib/radarr/.config/Radarr/radarr.db ".backup '/var/backup/radarr/radarr.db'"
          '';
        };
      };
    };
}
