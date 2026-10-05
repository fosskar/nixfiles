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
      mediaRoot = "/tank/media";
      serviceName = "shelfmark";
      localHost = "${serviceName}.${flake-self.domains.local}";
      listenAddress = "127.0.0.1";
      listenPort = 8084;
      listenUrl = "http://${listenAddress}:${toString listenPort}";
      autheliaEnabled = config.services.authelia.instances.main.enable or false;
      cfg = config.services.shelfmark;
    in
    {
      config = {
        # --- service ---

        services.shelfmark = {
          enable = true;
          openFirewall = false;
          environment = {
            FLASK_HOST = listenAddress;
            FLASK_PORT = listenPort;
            TMP_DIR = "${mediaRoot}/downloads/shelfmark";

            AUDIOBOOK_LIBRARY_URL = "https://audiobookshelf.${flake-self.domains.local}";

            # audiobookshelf expects one folder per book
            INGEST_DIR = "${mediaRoot}/books/ebooks";
            FILE_ORGANIZATION = "organize";
            TEMPLATE_ORGANIZE = "{Author}/{Title}/{Title}";
            DESTINATION_AUDIOBOOK = "${mediaRoot}/books/audiobooks";
            FILE_ORGANIZATION_AUDIOBOOK = "organize";

            PROWLARR_ENABLED = "true";
            PROWLARR_URL = "http://127.0.0.1:9696";
            PROWLARR_USENET_CLIENT = "sabnzbd";
            # sabnzbd host_whitelist rejects unknown Host headers; localhost passes
            SABNZBD_URL = "http://localhost:8085";
            # own category so chaptarr does not pick up shelfmark's jobs
            SABNZBD_CATEGORY = "shelfmark";
          }
          // lib.optionalAttrs autheliaEnabled {
            AUTH_METHOD = "proxy";
            PROXY_AUTH_USER_HEADER = "Remote-User";
            PROXY_AUTH_ADMIN_GROUP_HEADER = "Remote-Groups";
            PROXY_AUTH_ADMIN_GROUP_NAME = "admin";
            PROXY_AUTH_LOGOUT_URL = "https://auth.${flake-self.domains.public}/logout";
          };
        };

        services.authelia.instances.main.settings.access_control.rules = lib.mkIf autheliaEnabled (
          lib.mkBefore [
            {
              domain = [ localHost ];
              subject = [ "group:admin" ];
              policy = "one_factor";
            }
            {
              domain = [ localHost ];
              policy = "deny";
            }
          ]
        );

        systemd.tmpfiles.rules = [ "d ${cfg.environment.TMP_DIR} 2775 root media -" ];

        systemd.services.shelfmark = {
          after = [
            "prowlarr.service"
            "sabnzbd-api.service"
          ];
          wants = [
            "prowlarr.service"
            "sabnzbd-api.service"
          ];
          unitConfig.RequiresMountsFor = [ mediaRoot ];
          serviceConfig = {
            # the api keys exist only at runtime, so they are read at start
            ExecStart = lib.mkForce (
              pkgs.writeShellScript "shelfmark-start" ''
                PROWLARR_API_KEY=$(< /run/arr-api-keys/prowlarr/api-key)
                SABNZBD_API_KEY=$(< /run/arr-api-keys/sabnzbd/api-key)
                export PROWLARR_API_KEY SABNZBD_API_KEY
                exec ${lib.getExe cfg.package} -b ${cfg.environment.FLASK_HOST}:${cfg.environment.FLASK_PORT}
              ''
            );
            SupplementaryGroups = [
              "media"
              "prowlarr-api"
              "sabnzbd-api"
            ];
            ReadWritePaths = [
              "${mediaRoot}/books"
              "${mediaRoot}/downloads"
            ];
            UMask = lib.mkForce "0002";
          };
        };

        # --- homepage ---

        services.homepage-dashboard.services = [
          {
            "apps" = [
              {
                "Shelfmark" = {
                  href = "https://${localHost}";
                  icon = "sh-shelfmark";
                  siteMonitor = listenUrl;
                };
              }
            ];
          }
        ];

        # --- gatus ---

        services.gatus.settings.endpoints = [
          {
            name = "Shelfmark";
            # backend check on purpose: the edge is forward-auth, authelia answers 302 without reaching the service
            url = "${listenUrl}/api/health";
            enabled = true;
            alerts = [ { type = "matrix"; } ];
            interval = "5m";
            conditions = [ "[STATUS] == 200" ];
          }
        ];

        # --- caddy ---

        services.caddy.virtualHosts.${localHost}.extraConfig = ''
          ${lib.optionalString autheliaEnabled "import authelia"}
          reverse_proxy ${listenUrl}
        '';

        # --- backup ---

        clan.core.state.shelfmark = {
          folders = [ "/var/backup/shelfmark" ];
          preBackupScript = ''
            export PATH=${
              lib.makeBinPath [
                pkgs.sqlite
                pkgs.coreutils
              ]
            }
            mkdir -p /var/backup/shelfmark
            sqlite3 /var/lib/private/shelfmark/users.db ".backup '/var/backup/shelfmark/users.db'"
            cp /var/lib/private/shelfmark/settings.json /var/backup/shelfmark/settings.json
          '';
        };
      };
    };
}
