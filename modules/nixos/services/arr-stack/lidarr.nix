{
  flake.modules.nixos.arrStack =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      serviceName = "lidarr";
      localHost = "${serviceName}.${config.domains.local}";
      listenAddress = "127.0.0.1";
      listenPort = 8686;
      listenUrl = "http://${listenAddress}:${toString listenPort}";
    in
    {
      config = {
        # --- service ---

        services.lidarr = {
          enable = true;
          openFirewall = false;
          group = "media";
          settings = {
            auth = lib.mkIf (config.services.authelia.instances.main.enable or false) {
              method = "External";
              required = "Enabled";
            };
            server = {
              bindaddress = listenAddress;
              port = listenPort;
            };
          };
        };

        # preserve group-write on created files/dirs so other media-group
        # services can write into per-album subdirs.
        systemd.services.lidarr.serviceConfig.UMask = lib.mkForce "0002";

        # --- homepage ---

        services.homepage-dashboard.serviceGroups."Arr Stack" =
          lib.mkIf config.services.homepage-dashboard.enable
            [
              {
                "Lidarr" = {
                  href = "https://${localHost}";
                  icon = "lidarr.svg";
                  siteMonitor = listenUrl;
                };
              }
            ];

        # --- gatus ---

        services.gatus.settings.endpoints = lib.mkIf config.services.gatus.enable [
          {
            name = "Lidarr";
            url = listenUrl;
            group = "Arr Stack";
            enabled = true;
            interval = "5m";
            conditions = [ "[STATUS] == 200" ];
            alerts = [ { type = "email"; } ];
          }
        ];

        # --- caddy ---

        services.caddy.virtualHosts.${localHost}.extraConfig = ''
          ${lib.optionalString (config.services.authelia.instances.main.enable or false) "import authelia"}
          reverse_proxy ${listenUrl}
        '';

        # --- backup ---

        clan.core.state.lidarr = {
          folders = [ "/var/backup/lidarr" ];
          preBackupScript = ''
            export PATH=${
              lib.makeBinPath [
                pkgs.sqlite
                pkgs.coreutils
              ]
            }
            mkdir -p /var/backup/lidarr
            sqlite3 /var/lib/lidarr/.config/Lidarr/lidarr.db ".backup '/var/backup/lidarr/lidarr.db'"
          '';
        };
      };
    };
}
