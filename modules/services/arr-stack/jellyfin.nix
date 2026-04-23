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
      serviceDomain = "jellyfin.${acmeDomain}";
      bindAddress = "127.0.0.1";
      port = 8096;
      internalUrl = "http://${bindAddress}:${toString port}";
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

        services.homepage-dashboard.services = lib.mkIf config.services.homepage-dashboard.enable [
          {
            "Media" = [
              {
                "Jellyfin" = {
                  href = "https://${serviceDomain}";
                  icon = "jellyfin.png";
                  siteMonitor = internalUrl;
                };
              }
            ];
          }
        ];

        # --- gatus ---

        services.gatus.settings.endpoints = lib.mkIf config.services.gatus.enable [
          {
            name = "Jellyfin";
            url = internalUrl;
            group = "Media";
            enabled = true;
            interval = "5m";
            conditions = [ "[STATUS] == 200" ];
            alerts = [ { type = "ntfy"; } ];
          }
        ];

        # --- caddy ---

        # no proxy-auth - jellyfin has built-in auth
        services.caddy.virtualHosts."jellyfin.nx3.eu".extraConfig = ''
          reverse_proxy 127.0.0.1:${toString port}
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
