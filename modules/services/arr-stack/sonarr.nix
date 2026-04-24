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
      serviceDomain = "sonarr.${acmeDomain}";
      bindAddress = "127.0.0.1";
      port = 8989;
      internalUrl = "http://${bindAddress}:${toString port}";
    in
    {
      config = {
        # --- service ---

        services.sonarr = {
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
                "Sonarr" = {
                  href = "https://${serviceDomain}";
                  icon = "sonarr.svg";
                  siteMonitor = internalUrl;
                };
              }
            ];

        # --- gatus ---

        services.gatus.settings.endpoints = lib.mkIf config.services.gatus.enable [
          {
            name = "Sonarr";
            url = internalUrl;
            group = "Arr Stack";
            enabled = true;
            interval = "5m";
            conditions = [ "[STATUS] == 200" ];
            alerts = [ { type = "ntfy"; } ];
          }
        ];

        # --- caddy ---

        services.caddy.virtualHosts."sonarr.nx3.eu".extraConfig = ''
          ${lib.optionalString (config.services.authelia.instances.main.enable or false) "import authelia"}
          reverse_proxy 127.0.0.1:${toString port}
        '';

        # --- backup ---

        clan.core.state.sonarr = {
          folders = [ "/var/backup/sonarr" ];
          preBackupScript = ''
            export PATH=${
              lib.makeBinPath [
                pkgs.sqlite
                pkgs.coreutils
              ]
            }
            mkdir -p /var/backup/sonarr
            sqlite3 /var/lib/sonarr/.config/NzbDrone/sonarr.db ".backup '/var/backup/sonarr/sonarr.db'"
          '';
        };
      };
    };
}
