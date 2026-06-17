{
  flake.modules.nixos.arrStack =
    {
      flake-self,
      config,
      lib,
      pkgs,
      ...
    }:
    let
      serviceName = "radarr";
      localHost = "${serviceName}.${flake-self.domains.local}";
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
        # services (bazarr) can write subtitles into per-movie subdirs.
        systemd.services.radarr.serviceConfig.UMask = lib.mkForce "0002";

        # --- homepage ---

        services.homepage-dashboard.serviceGroups."arr-stack" = [
          {
            "Radarr" = {
              href = "https://${localHost}";
              icon = "radarr.svg";
              siteMonitor = listenUrl;
            };
          }
        ];

        # --- gatus ---

        services.gatus.settings.endpoints = [
          {
            name = "Radarr";
            url = listenUrl;
            group = "Arr Stack";
            enabled = true;
            alerts = [ { type = "email"; } ];
            interval = "5m";
            conditions = [ "[STATUS] == 200" ];
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
