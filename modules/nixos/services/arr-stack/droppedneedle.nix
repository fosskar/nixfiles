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
      generators = config.clan.core.vars.generators;
      sabnzbd = config.services.sabnzbd.settings.misc;
      prowlarr = config.services.prowlarr.settings.server;
      # the admin account droppedneedle-sync signs in as
      syncUser = "simon";
      keyUnits = [
        "sabnzbd-api.service"
        "prowlarr-api.service"
      ];
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

        clan.core.vars.generators.droppedneedle-sync = {
          prompts = {
            password = {
              description = "droppedneedle password of the account ${syncUser}";
              type = "hidden";
              persist = true;
            };
          };
          files.password.restartUnits = [ "droppedneedle-sync.service" ];
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
          # python plugins run through python3 from PATH
          path = [ pkgs.python3 ];
          environment = {
            ROOT_APP_DIR = stateDir;
            BIND_HOST = listenAddress;
            PORT = toString listenPort;
            # unset, the server calls itself a dev build and always offers an update
            COMMIT_TAG = "v${pkgs.local.droppedneedle.version}";
            # the daily scan runs at its set time in this zone; the host is on utc
            TZ = "Europe/Berlin";
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

        # --- settings ---

        # droppedneedle keeps its settings in the database and has no config
        # file. a write replaces its whole section, so every field is sent
        systemd.services.droppedneedle-sync = {
          description = "sync settings into droppedneedle";
          after = [ "droppedneedle.service" ] ++ keyUnits;
          requires = [ "droppedneedle.service" ] ++ keyUnits;
          wantedBy = [ "multi-user.target" ];
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            DynamicUser = true;
            SupplementaryGroups = [
              "sabnzbd-api"
              "prowlarr-api"
            ];
            LoadCredential = [
              "password:${generators.droppedneedle-sync.files.password.path}"
              "oidc-client-secret:${generators.droppedneedle.files."oidc-client-secret".path}"
            ];
            ProtectSystem = "strict";
            ProtectHome = true;
            PrivateDevices = true;
            NoNewPrivileges = true;
            RestrictAddressFamilies = [
              "AF_INET"
              "AF_INET6"
            ];
            CapabilityBoundingSet = "";
            ExecStart = pkgs.writeShellScript "droppedneedle-sync" ''
              set -eu
              export PATH=${
                lib.makeBinPath [
                  pkgs.coreutils
                  pkgs.curl
                  pkgs.jq
                ]
              }

              # secrets reach curl and jq through files: argv is world-readable
              # in /proc/<pid>/cmdline
              umask 077
              base=${listenUrl}/api/v3
              ready=""
              for _ in $(seq 60); do
                if curl -sf ${listenUrl}/health >/dev/null; then
                  ready=yes
                  break
                fi
                sleep 2
              done
              if [ -z "$ready" ]; then
                echo "droppedneedle is not answering on ${listenUrl}" >&2
                exit 1
              fi

              jq -n --rawfile password "$CREDENTIALS_DIRECTORY/password" \
                '{username: "${syncUser}", password: ($password | sub("\n+$"; "")), transport: "bearer"}' \
                | curl -sfS -H 'Content-Type: application/json' --data-binary @- "$base/auth/login" \
                | jq -re '"Authorization: Bearer " + .token' > /tmp/token.header
              api() {
                method=$1
                path=$2
                shift 2
                curl -sfS -X "$method" -H @/tmp/token.header -H 'Content-Type: application/json' "$@" "$base$path"
              }
              # a login makes a session that lasts 30 days
              trap 'api POST /auth/logout >/dev/null' EXIT

              jq -n --rawfile secret "$CREDENTIALS_DIRECTORY/oidc-client-secret" '{
                enabled: true,
                issuer: "https://auth.${flake-self.domains.public}",
                client_id: "${serviceName}",
                client_secret: ($secret | sub("\n+$"; "")),
                redirect_uri: "${oidcRedirectUri}",
                scopes: "openid email profile",
                auto_redirect: false
              }' | api PUT /settings/oidc --data-binary @- >/dev/null
              echo "synced oidc"

              jq -n --rawfile key /run/arr-api-keys/sabnzbd/api-key '{
                enabled: true,
                url: "http://${sabnzbd.host}:${toString sabnzbd.port}",
                api_key: ($key | sub("\n+$"; "")),
                category: "music",
                priority: 0,
                downloads_mount: "${sabnzbd.complete_dir}"
              }' | api PUT /settings/download-clients/sabnzbd --data-binary @- >/dev/null
              echo "synced sabnzbd"

              jq -n --rawfile key /run/arr-api-keys/prowlarr/api-key '{
                enabled: true,
                url: "http://${prowlarr.bindaddress}:${toString prowlarr.port}",
                api_key: ($key | sub("\n+$"; ""))
              }' | api PUT /settings/prowlarr/config --data-binary @- >/dev/null
              echo "synced prowlarr"
            '';
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
