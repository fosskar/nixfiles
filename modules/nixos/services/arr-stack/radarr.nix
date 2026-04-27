{
  flake.modules.nixos.arrStack =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      serviceName = "radarr";
      localHost = "${serviceName}.${config.domains.local}";
      listenAddress = "127.0.0.1";
      listenPort = 7878;
      listenUrl = "http://${listenAddress}:${toString listenPort}";
    in
    {
      config = {
        # --- service ---

        services.radarr = {
          enable = true;
          openFirewall = false;
          group = "media";
          settings.server.port = listenPort;
        };

        # preserve group-write on created files/dirs so other media-group
        # services (bazarr) can write subtitles into per-movie subdirs.
        systemd.services.radarr.serviceConfig.UMask = lib.mkForce "0002";

        # --- homepage ---

        services.homepage-dashboard.serviceGroups."Arr Stack" =
          lib.mkIf config.services.homepage-dashboard.enable
            [
              {
                "Radarr" = {
                  href = "https://${localHost}";
                  icon = "radarr.svg";
                  siteMonitor = listenUrl;
                };
              }
            ];

        # --- gatus ---

        services.gatus.settings.endpoints = lib.mkIf config.services.gatus.enable [
          {
            name = "Radarr";
            url = listenUrl;
            group = "Arr Stack";
            enabled = true;
            interval = "5m";
            conditions = [ "[STATUS] == 200" ];
            alerts = [ { type = "ntfy"; } ];
          }
        ];

        # --- caddy ---

        services.caddy.virtualHosts.${localHost}.extraConfig = ''
          ${lib.optionalString (config.services.authelia.instances.main.enable or false) "import authelia"}
          reverse_proxy ${listenUrl}
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
