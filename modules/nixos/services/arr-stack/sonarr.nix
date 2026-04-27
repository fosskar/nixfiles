{
  flake.modules.nixos.arrStack =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      serviceName = "sonarr";
      localHost = "${serviceName}.${config.domains.local}";
      listenAddress = "127.0.0.1";
      listenPort = 8989;
      listenUrl = "http://${listenAddress}:${toString listenPort}";
    in
    {
      config = {
        # --- service ---

        services.sonarr = {
          enable = true;
          openFirewall = false;
          group = "media";
          settings.server.port = listenPort;
        };

        # preserve group-write on created files/dirs so other media-group
        # services (bazarr) can write subtitles into per-show subdirs.
        systemd.services.sonarr.serviceConfig.UMask = lib.mkForce "0002";

        # --- homepage ---

        services.homepage-dashboard.serviceGroups."Arr Stack" =
          lib.mkIf config.services.homepage-dashboard.enable
            [
              {
                "Sonarr" = {
                  href = "https://${localHost}";
                  icon = "sonarr.svg";
                  siteMonitor = listenUrl;
                };
              }
            ];

        # --- gatus ---

        services.gatus.settings.endpoints = lib.mkIf config.services.gatus.enable [
          {
            name = "Sonarr";
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
