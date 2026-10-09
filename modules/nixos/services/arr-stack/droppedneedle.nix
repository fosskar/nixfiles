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
      stateDir = "/var/lib/${serviceName}";
      oidcIssuerUrl = "https://auth.${flake-self.domains.public}";
      mediaRoot = "/tank/media";

      # keys set here are rewritten on every start; everything else in
      # config.json stays managed through the web ui
      settings = {
        library_root = {
          id = "6f3c2a1e-9d4b-4c8a-b7e5-2f1d0c9a8b7e";
          path = "${mediaRoot}/music";
          label = "music";
          policy = "automatic";
          rules = [ ];
        };
        oidc_settings = {
          enabled = true;
          issuer = oidcIssuerUrl;
          client_id = serviceName;
          scopes = "openid email profile";
          redirect_uri = "https://${localHost}/api/v1/auth/oidc/callback";
        };
        sabnzbd = {
          enabled = true;
          client_type = "sabnzbd";
          url = "http://127.0.0.1:${toString config.services.sabnzbd.settings.misc.port}";
          category = "music";
          priority = 0;
          post_processing = 3;
          downloads_mount = config.services.sabnzbd.settings.misc.complete_dir;
        };
        prowlarr = {
          enabled = true;
          url = "http://127.0.0.1:${toString config.services.prowlarr.settings.server.port}";
        };
        lidarr_import = {
          url = "http://127.0.0.1:${toString config.services.lidarr.settings.server.port}";
        };
      };

      configureScript = pkgs.writeShellScript "droppedneedle-configure" ''
        set -eu
        config=${stateDir}/config/config.json
        mkdir -p ${stateDir}/config
        [ -f "$config" ] || echo '{}' > "$config"

        ${lib.getExe pkgs.jq} \
          --argjson settings ${lib.escapeShellArg (builtins.toJSON settings)} \
          --rawfile oidcSecret "$CREDENTIALS_DIRECTORY/oidc-client-secret" \
          --rawfile sabnzbdKey "$CREDENTIALS_DIRECTORY/sabnzbd-api-key" \
          --rawfile prowlarrKey "$CREDENTIALS_DIRECTORY/prowlarr-api-key" \
          --rawfile lidarrKey "$CREDENTIALS_DIRECTORY/lidarr-api-key" \
          '
            .library_settings.library_roots = [ $settings.library_root ]
            | .oidc_settings = $settings.oidc_settings + { client_secret: ($oidcSecret | rtrimstr("\n")) }
            | .download_clients.sabnzbd = $settings.sabnzbd + { api_key: ($sabnzbdKey | rtrimstr("\n")) }
            | .prowlarr = $settings.prowlarr + { api_key: ($prowlarrKey | rtrimstr("\n")) }
            | .lidarr_import = $settings.lidarr_import + { api_key: ($lidarrKey | rtrimstr("\n")) }
            | .usenet_search_backend = "prowlarr"
            | .source_priority = [ "usenet", "soulseek" ]
          ' "$config" > "$config.new"
        mv "$config.new" "$config"
      '';
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
            redirect_uris = [ settings.oidc_settings.redirect_uri ];
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
          # the api key files only exist once these have run
          after = [
            "network-online.target"
            "sabnzbd-api.service"
            "prowlarr.service"
            "lidarr-api.service"
          ];
          wants = [
            "network-online.target"
            "sabnzbd-api.service"
            "prowlarr.service"
            "lidarr-api.service"
          ];
          environment = {
            ROOT_APP_DIR = stateDir;
            BIND_HOST = listenAddress;
            PORT = toString listenPort;
          };
          serviceConfig = {
            ExecStartPre = configureScript;
            ExecStart = lib.getExe pkgs.local.droppedneedle;
            LoadCredential = [
              "oidc-client-secret:${
                config.clan.core.vars.generators.droppedneedle.files."oidc-client-secret".path
              }"
              "sabnzbd-api-key:/run/arr-api-keys/sabnzbd/api-key"
              "prowlarr-api-key:/run/arr-api-keys/prowlarr/api-key"
              "lidarr-api-key:/run/arr-api-keys/lidarr/api-key"
            ];
            DynamicUser = true;
            SupplementaryGroups = [ "media" ];
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
                  icon = "mdi-record-player";
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

        # no proxy-auth - droppedneedle has built-in auth
        services.caddy.virtualHosts.${localHost}.extraConfig = ''
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
            sqlite3 ${stateDir}/cache/library.db ".backup '/var/backup/droppedneedle/library.db'"
            cp -r ${stateDir}/config /var/backup/droppedneedle/
          '';
        };
      };
    };
}
