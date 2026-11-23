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
      serviceName = "droppedneedle";
      localHost = "music.${flake-self.domains.local}";
      listenAddress = "127.0.0.1";
      listenPort = 8688;
      listenUrl = "http://${listenAddress}:${toString listenPort}";
      # droppedneedle refuses a database below a symlink, and with DynamicUser
      # /var/lib/droppedneedle is one
      stateDir = "/var/lib/private/${serviceName}";
      musicDir = "/tank/media/music";
      oidcRedirectUri = "https://${localHost}/api/v3/auth/oidc/callback";
    in
    {
      config = {
        # --- secrets ---

        clan.core.vars.generators.droppedneedle = {
          files = {
            "oidc-client-secret" = { };
            "oidc-client-secret-hash" = {
              owner = "authelia-main";
              group = "authelia-main";
            };
          };
          runtimeInputs = [
            pkgs.pwgen
            config.services.authelia.instances.main.package
          ];
          script = ''
            pwgen -s 64 1 | tr -d '\n' > "$out/oidc-client-secret"
            authelia crypto hash generate pbkdf2 --password "$(cat "$out/oidc-client-secret")" | tail -1 | cut -d' ' -f2 > "$out/oidc-client-secret-hash"
          '';
        };

        # --- authelia ---

        services.authelia.instances.main.settings.identity_providers.oidc.clients = [
          {
            client_id = serviceName;
            client_name = "DroppedNeedle";
            client_secret = "{{ secret \"${
              config.clan.core.vars.generators.droppedneedle.files."oidc-client-secret-hash".path
            }\" }}";
            public = false;
            consent_mode = "implicit";
            authorization_policy = "users";
            redirect_uris = [ oidcRedirectUri ];
            scopes = [
              "openid"
              "profile"
              "email"
            ];
            response_types = [ "code" ];
            grant_types = [ "authorization_code" ];
            token_endpoint_auth_method = "client_secret_post";
          }
        ];

        # --- service ---

        systemd.services.droppedneedle = {
          description = "DroppedNeedle";
          wantedBy = [ "multi-user.target" ];
          after = [ "network-online.target" ];
          wants = [ "network-online.target" ];
          environment = {
            ROOT_APP_DIR = stateDir;
            BIND_HOST = listenAddress;
            PORT = toString listenPort;
          };
          serviceConfig = {
            ExecStart = lib.getExe pkgs.local.droppedneedle;
            DynamicUser = true;
            SupplementaryGroups = [ "media" ];
            # DynamicUser implies ProtectSystem=strict
            ReadWritePaths = [
              musicDir
              config.services.sabnzbd.settings.misc.complete_dir
            ];
            StateDirectory = serviceName;
            WorkingDirectory = stateDir;
            UMask = "0002";
            Restart = "on-failure";
          };
        };

        # --- homepage ---

        services.homepage-dashboard.services = [
          {
            "media" = [
              {
                "DroppedNeedle" = {
                  href = "https://${localHost}";
                  icon = "https://${localHost}/logo_icon.png";
                  siteMonitor = listenUrl;
                };
              }
            ];
          }
        ];

        # --- gatus ---

        services.gatus.settings.endpoints = [
          {
            name = "DroppedNeedle";
            url = "https://${localHost}/health";
            enabled = true;
            alerts = [ { type = "matrix"; } ];
            interval = "5m";
            conditions = [ "[STATUS] == 200" ];
          }
        ];

        # --- caddy ---

        # no proxy-auth - droppedneedle has built-in auth. plex is not configured,
        # and in that state its plex login accepts any plex.tv account
        services.caddy.virtualHosts.${localHost}.extraConfig = ''
          @plexlogin path /api/v3/auth/plex /api/v3/auth/plex/*
          respond @plexlogin 403
          reverse_proxy ${listenUrl}
        '';

        # --- backup ---

        clan.core.state.droppedneedle = {
          folders = [ "/var/backup/droppedneedle" ];
          preBackupScript = ''
            export PATH=${
              lib.makeBinPath [
                pkgs.sqlite
                pkgs.coreutils
              ]
            }
            mkdir -p /var/backup/droppedneedle
            sqlite3 -nofollow ${stateDir}/cache/library.db ".backup '/var/backup/droppedneedle/library.db'"
            # a leftover entry from the last run would fail the whole backup job
            rm -rf /var/backup/droppedneedle/config
            cp -r ${stateDir}/config /var/backup/droppedneedle/
          '';
        };
      };
    };
}
