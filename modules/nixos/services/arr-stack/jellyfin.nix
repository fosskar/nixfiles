{
  flake.modules.nixos.arrStack =
    {
      config,
      domains,
      lib,
      pkgs,
      ...
    }:
    let
      serviceName = "jellyfin";
      localHost = "${serviceName}.${domains.local}";
      listenAddress = "127.0.0.1";
      listenPort = 8096;
      listenUrl = "http://${listenAddress}:${toString listenPort}";
    in
    {
      config = {
        # --- service ---

        services.jellyfin = {
          enable = true;
          openFirewall = false;
          group = "media";
          hardwareAcceleration = {
            device = "/dev/dri/renderD128";
            type = "qsv";
          };
        };

        users.users.jellyfin.extraGroups = [
          "render"
          "video"
        ];

        environment.systemPackages = with pkgs; [
          jellyfin
          jellyfin-web
          jellyfin-ffmpeg
        ];

        # --- homepage ---

        services.homepage-dashboard.serviceGroups."Media" =
          lib.mkIf config.services.homepage-dashboard.enable
            [
              {
                "Jellyfin" = {
                  href = "https://${localHost}";
                  icon = "jellyfin.png";
                  siteMonitor = listenUrl;
                };
              }
            ];

        # --- gatus ---

        services.gatus.settings.endpoints = lib.mkIf config.services.gatus.enable [
          {
            name = "Jellyfin";
            url = listenUrl;
            group = "Media";
            enabled = true;
            interval = "5m";
            conditions = [ "[STATUS] == 200" ];
            alerts = [ { type = "ntfy"; } ];
          }
        ];

        # --- caddy ---

        # no proxy-auth - jellyfin has built-in auth
        services.caddy.virtualHosts.${localHost}.extraConfig = ''
          reverse_proxy ${listenUrl}
        '';

        # --- backup ---

        clan.core.state.jellyfin = {
          folders = [ "/var/backup/jellyfin" ];
          preBackupScript = ''
            export PATH=${
              lib.makeBinPath [
                pkgs.sqlite
                pkgs.coreutils
              ]
            }
            mkdir -p /var/backup/jellyfin
            sqlite3 /var/lib/jellyfin/data/jellyfin.db ".backup '/var/backup/jellyfin/jellyfin.db'"
          '';
        };

        # --- systemd ---

        systemd.services.jellyfin.environment = {
          LIBVA_DRIVER_NAME = "iHD";
        };
      };
    };
}
