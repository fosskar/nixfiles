{
  flake.modules.nixos.arrStack =
    {
      config,
      flake-self,
      lib,
      pkgs,
      ...
    }:
    let
      serviceName = "audiobookshelf";
      localHost = "${serviceName}.${flake-self.domains.local}";
      listenAddress = "127.0.0.1";
      listenPort = 13378;
      listenUrl = "http://${listenAddress}:${toString listenPort}";
    in
    {
      config = {
        # --- oidc ---

        clan.core.vars.generators.audiobookshelf = {
          files."oauth-client-secret-hash" = {
            owner = "authelia-main";
            group = "authelia-main";
          };
          # audiobookshelf keeps its oidc settings in its database, set via the
          # web ui; read this with `clan vars get` and paste it there
          files."oauth-client-secret".deploy = false;
          runtimeInputs = [
            pkgs.pwgen
            pkgs.authelia
          ];
          script = ''
            SECRET=$(pwgen -s 64 1)
            authelia crypto hash generate pbkdf2 --password "$SECRET" | tail -1 | cut -d' ' -f2 > "$out/oauth-client-secret-hash"
            echo -n "$SECRET" > "$out/oauth-client-secret"
          '';
        };

        services.authelia.instances.main.settings.identity_providers.oidc.clients = [
          {
            client_id = serviceName;
            client_name = "Audiobookshelf";
            client_secret = "{{ secret \"${
              config.clan.core.vars.generators.audiobookshelf.files."oauth-client-secret-hash".path
            }\" }}";
            public = false;
            consent_mode = "implicit";
            authorization_policy = "users";
            require_pkce = true;
            pkce_challenge_method = "S256";
            redirect_uris = [
              "https://${localHost}/audiobookshelf/auth/openid/callback"
              "https://${localHost}/audiobookshelf/auth/openid/mobile-redirect"
              "audiobookshelf://oauth"
            ];
            scopes = [
              "openid"
              "profile"
              "email"
              "groups"
            ];
            response_types = [ "code" ];
            grant_types = [ "authorization_code" ];
            access_token_signed_response_alg = "none";
            userinfo_signed_response_alg = "none";
            token_endpoint_auth_method = "client_secret_basic";
          }
        ];

        # --- service ---

        services.audiobookshelf = {
          enable = true;
          host = listenAddress;
          port = listenPort;
          openFirewall = false;
          group = "media";
        };

        systemd.services.audiobookshelf.serviceConfig.UMask = "0002";

        # --- email ---

        # audiobookshelf keeps email settings only in its database and its api
        # keys are created by a logged-in admin, so the key is entered once
        clan.core.vars.generators.audiobookshelf-api = {
          prompts.api-key = {
            description = "audiobookshelf admin api key (settings > api keys)";
            type = "hidden";
            persist = true;
          };
          files.api-key.restartUnits = [ "audiobookshelf-email-sync.service" ];
        };

        # e-reader devices stay in the ui; the patch only sets the fields it sends
        systemd.services.audiobookshelf-email-sync = {
          description = "sync smtp settings into audiobookshelf";
          after = [ "audiobookshelf.service" ];
          requires = [ "audiobookshelf.service" ];
          wantedBy = [ "multi-user.target" ];
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            DynamicUser = true;
            EnvironmentFile = config.clan.core.vars.generators.smtp.files."smtp-env".path;
            LoadCredential = "api-key:${config.clan.core.vars.generators.audiobookshelf-api.files.api-key.path}";
            ProtectSystem = "strict";
            ProtectHome = true;
            PrivateDevices = true;
            NoNewPrivileges = true;
            RestrictAddressFamilies = [
              "AF_INET"
              "AF_INET6"
            ];
            CapabilityBoundingSet = "";
            ExecStart = pkgs.writeShellScript "audiobookshelf-email-sync" ''
              set -eu
              export PATH=${
                lib.makeBinPath [
                  pkgs.coreutils
                  pkgs.curl
                  pkgs.jq
                ]
              }

              key=$(cat "$CREDENTIALS_DIRECTORY/api-key")
              base=${listenUrl}/audiobookshelf

              for _ in $(seq 60); do
                curl -sf "$base/status" >/dev/null && break
                sleep 2
              done

              # port 587 is starttls, so secure stays off
              jq -n \
                --arg host "$SMTP_HOST" --argjson port "$SMTP_PORT" \
                --arg user "$SMTP_USER" --arg pass "$SMTP_PASSWORD" --arg from "$SMTP_FROM" \
                '{host: $host, port: $port, secure: false, rejectUnauthorized: true, user: $user, pass: $pass, fromAddress: $from}' \
                | curl -sfS -X PATCH -H "Authorization: Bearer $key" -H 'Content-Type: application/json' \
                    --data-binary @- "$base/api/emails/settings" >/dev/null
              echo "updated audiobookshelf email settings"
            '';
          };
        };

        # --- homepage ---

        services.homepage-dashboard.services = [
          {
            "media" = [
              {
                "Audiobookshelf" = {
                  href = "https://${localHost}";
                  icon = "sh-audiobookshelf";
                  siteMonitor = listenUrl;
                };
              }
            ];
          }
        ];

        # --- gatus ---

        services.gatus.settings.endpoints = [
          {
            name = "Audiobookshelf";
            url = "https://${localHost}/healthcheck";
            enabled = true;
            alerts = [ { type = "matrix"; } ];
            interval = "5m";
            conditions = [ "[STATUS] == 200" ];
          }
        ];

        # --- caddy ---

        # no proxy-auth - audiobookshelf has built-in auth
        services.caddy.virtualHosts.${localHost}.extraConfig = ''
          reverse_proxy ${listenUrl}
        '';

        # --- backup ---

        clan.core.state.audiobookshelf = {
          folders = [ "/var/backup/audiobookshelf" ];
          preBackupScript = ''
            export PATH=${
              lib.makeBinPath [
                pkgs.sqlite
                pkgs.coreutils
              ]
            }
            mkdir -p /var/backup/audiobookshelf
            sqlite3 /var/lib/audiobookshelf/config/absdatabase.sqlite ".backup '/var/backup/audiobookshelf/absdatabase.sqlite'"
          '';
        };
      };
    };
}
