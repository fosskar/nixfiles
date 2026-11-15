{
  flake.modules.nixos.silo =
    {
      flake-self,
      config,
      lib,
      options,
      pkgs,
      ...
    }:
    let
      serviceName = "silo";
      localHost = "${serviceName}.${flake-self.domains.local}";
      # silo binds every port to all interfaces; the firewall stays closed
      listenPort = 8190;
      listenUrl = "http://127.0.0.1:${toString listenPort}";
      dataDir = "/var/lib/silo";
      mediaRoot = "/tank/media";
      redis = config.services.redis.servers.silo;
      apiUrl = "${listenUrl}/api/v2";
      generators = config.clan.core.vars.generators;
      llamaCpp = config.services.llama-cpp.settings;
      embeddingModel = "qwen3-embedding-0.6b";
      oidcPlugin = "silo.auth.oidc";
      # the callback path carries the plugin's installation id, a database
      # serial that only exists after the install, so every id it can
      # plausibly get is registered
      oidcRedirectUris = map (id: "https://${localHost}/api/v2/auth/oauth/${toString id}/callback") (
        lib.range 1 20
      );
    in
    {
      config = {
        # --- service ---

        clan.core.vars.generators.silo = {
          files."secret.env" = { };

          runtimeInputs = [ pkgs.pwgen ];
          script = ''
            echo "SECRET_KEY=$(pwgen -s 64 1)" > "$out/secret.env"
          '';
        };

        users.groups = {
          silo = { };
          media = { };
        };
        users.users.silo = {
          isSystemUser = true;
          group = "silo";
          home = dataDir;
          extraGroups = [
            "media"
            "render"
            "video"
            redis.group
          ];
        };

        services.redis.servers.silo.enable = true;

        systemd.services.silo = {
          description = "silo media server";
          after = [
            "network-online.target"
            "postgresql.service"
            "redis-silo.service"
            "silo-postgresql-extensions.service"
          ];
          wants = [ "network-online.target" ];
          requires = [
            "postgresql.service"
            "redis-silo.service"
            "silo-postgresql-extensions.service"
          ];
          wantedBy = [ "multi-user.target" ];
          # silo marks files missing when it scans an unmounted library
          unitConfig.RequiresMountsFor = [ mediaRoot ];
          # backups run pg_dump
          path = [ config.services.postgresql.package ];
          environment = {
            PORT = toString listenPort;
            # jellyfin has 8096 and audiobookshelf 13378
            JF_PORT = "8196";
            ABS_PORT = "13379";
            DATABASE_URL = "postgres://silo@/silo?host=/run/postgresql&sslmode=disable";
            REDIS_URL = "unix://${redis.unixSocket}";
            SILO_PLUGIN_CACHE_DIR = "${dataDir}/plugins";
            HOME = dataDir;
          };
          serviceConfig = {
            User = "silo";
            Group = "silo";
            StateDirectory = "silo";
            WorkingDirectory = dataDir;
            EnvironmentFile = config.clan.core.vars.generators.silo.files."secret.env".path;
            ExecStart = lib.getExe pkgs.local.silo-server;
            # the restart button in the admin ui exits cleanly
            Restart = "always";
            # transcodes go to /tmp/silo-transcode
            PrivateTmp = true;
          };
        };

        # --- settings ---

        clan.core.vars.generators.silo-api = {
          prompts.api-key = {
            description = "silo admin api key (profile menu > api keys)";
            type = "hidden";
            persist = true;
          };
          files.api-key.restartUnits = [ "silo-sync.service" ];
        };

        clan.core.vars.generators.silo-oidc = {
          files = {
            "oauth-client-secret-hash" = {
              owner = "authelia-main";
              group = "authelia-main";
            };
            "oauth-client-secret".restartUnits = [ "silo-sync.service" ];
          };

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
            client_id = "silo";
            client_name = "Silo";
            client_secret = "{{ secret \"${generators.silo-oidc.files."oauth-client-secret-hash".path}\" }}";
            public = false;
            consent_mode = "implicit";
            authorization_policy = "users";
            redirect_uris = oidcRedirectUris;
            scopes = [
              "openid"
              "profile"
              "email"
              "groups"
            ];
            response_types = [ "code" ];
            grant_types = [ "authorization_code" ];
            token_endpoint_auth_method = "client_secret_basic";
          }
        ];

        # silo keeps its settings in the database; only the fields sent here
        # are forced, anything else set in the admin ui survives
        systemd.services.silo-sync = {
          description = "sync settings into silo";
          after = [ "silo.service" ];
          requires = [ "silo.service" ];
          wantedBy = [ "multi-user.target" ];
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            DynamicUser = true;
            EnvironmentFile = generators.smtp.files."smtp-env".path;
            LoadCredential = [
              "api-key:${generators.silo-api.files.api-key.path}"
              "oidc-client-secret:${generators.silo-oidc.files."oauth-client-secret".path}"
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
            ExecStart = pkgs.writeShellScript "silo-sync" ''
              set -eu
              export PATH=${
                lib.makeBinPath [
                  pkgs.coreutils
                  pkgs.curl
                  pkgs.jq
                ]
              }

              # secrets reach curl and jq through files and the environment:
              # argv is world-readable in /proc/<pid>/cmdline
              umask 077
              printf 'Authorization: Bearer %s\n' "$(cat "$CREDENTIALS_DIRECTORY/api-key")" > /tmp/api-key.header
              base=${apiUrl}

              api() {
                method=$1
                path=$2
                shift 2
                curl -sfS -X "$method" -H @/tmp/api-key.header -H 'Content-Type: application/json' "$@" "$base$path"
              }

              ready=""
              for _ in $(seq 60); do
                if curl -sf ${listenUrl}/api/v1/health >/dev/null; then
                  ready=yes
                  break
                fi
                sleep 2
              done
              if [ -z "$ready" ]; then
                echo "silo is not answering on ${listenUrl}" >&2
                exit 1
              fi

              # ai provider: the llama-cpp router on this host
              provider_fields=${
                lib.escapeShellArg (
                  builtins.toJSON {
                    name = "llama-cpp";
                    base_url = "http://${llamaCpp.host}:${toString llamaCpp.port}";
                    capabilities = [
                      "chat"
                      "embeddings"
                    ];
                  }
                )
              }
              provider=$(api GET /admin/ai/providers | jq -r '.providers[] | select(.name == "llama-cpp") | .id')
              if [ -n "$provider" ]; then
                api PATCH "/admin/ai/providers/$provider" --data-binary "$provider_fields" >/dev/null
              else
                provider=$(jq -c '. + {type: "custom"}' <<<"$provider_fields" \
                  | api POST /admin/ai/providers --data-binary @- | jq -re .id)
              fi
              echo "ai provider llama-cpp is $provider"

              # oidc plugin
              installation=$(api GET /admin/plugins/installations \
                | jq -r '.items[] | select(.plugin_id == "${oidcPlugin}") | .id')
              if [ -z "$installation" ]; then
                installation=$(api GET /admin/plugins/catalog \
                  | jq -ce '.items[] | select(.plugin_id == "${oidcPlugin}") | {plugin_id, repository_id, version}' \
                  | api POST /admin/plugins/installations --data-binary @- | jq -re .id)
                echo "installed ${oidcPlugin} as installation $installation"
              fi
              jq -n --rawfile secret "$CREDENTIALS_DIRECTORY/oidc-client-secret" '{
                key: "connection",
                value: {
                  issuer_url: "https://auth.${flake-self.domains.public}",
                  client_id: "silo",
                  client_secret: $secret,
                  request_groups_scope: true
                }
              }' | api PUT "/admin/plugins/installations/$installation/config" --data-binary @-
              api PUT "/admin/plugins/installations/$installation/config" \
                --data-binary '{"key": "display_name", "value": {"value": "Authelia"}}'
              api PUT "/admin/plugins/installations/$installation/config" \
                --data-binary '{"key": "access", "value": {"admin_groups": "admin"}}'
              api PUT "/admin/plugins/installations/$installation/auth-binding" \
                --data-binary '{"capability_id": "oidc", "enabled": true, "display_order": 0, "default_login": false, "auto_provision": true}'
              echo "configured ${oidcPlugin} installation $installation"

              # port 587 is starttls
              result=$(jq -n --arg provider "$provider" '{
                values: {
                  "server.public_url": "https://${localHost}",
                  "email.enabled": "true",
                  "email.smtp_host": $ENV.SMTP_HOST,
                  "email.smtp_port": $ENV.SMTP_PORT,
                  "email.smtp_security": "starttls",
                  "email.smtp_username": $ENV.SMTP_USER,
                  "email.smtp_password": $ENV.SMTP_PASSWORD,
                  "email.from_address": $ENV.SMTP_FROM,
                  "recommendations.enabled": "true",
                  "recommendations.embedding_provider_id": $provider,
                  "recommendations.embedding_model": "${embeddingModel}"
                }
              }' | api PUT /admin/settings -H 'If-Match: *' --data-binary @-)
              echo "updated settings"

              # the embedding engine is built at startup
              if [ "$(jq -r .restart_required <<<"$result")" = true ]; then
                api POST /admin/server/restart --data-binary '{"reason": "settings sync"}' >/dev/null
                echo "restarted silo for: $(jq -r '.restart_required_keys | join(", ")' <<<"$result")"
              fi
            '';
          };
        };

        # --- database ---

        services.postgresql.extensions = ps: [ ps.pgvector ];

        clan.core.postgresql.enable = true;
        clan.core.postgresql.users.silo = { };
        clan.core.postgresql.databases.silo = {
          create.options.OWNER = "silo";
          restore.stopOnRestore = [ "silo.service" ];
        };

        # pgvector is not a trusted extension, so the database owner cannot
        # create it in the migrations
        systemd.services.silo-postgresql-extensions = {
          description = "create the pgvector extension for silo";
          after = [ "postgresql.service" ];
          requires = [ "postgresql.service" ];
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            User = "postgres";
            ExecStart = "${lib.getExe' config.services.postgresql.package "psql"} -d silo -c 'CREATE EXTENSION IF NOT EXISTS vector'";
          };
        };

        # --- homepage ---

        services.homepage-dashboard.services = [
          {
            "media" = [
              {
                "Silo" = {
                  href = "https://${localHost}";
                  icon = "mdi-silo";
                  siteMonitor = listenUrl;
                };
              }
            ];
          }
        ];

        # --- gatus ---

        services.gatus.settings.endpoints = [
          {
            name = "Silo";
            url = "https://${localHost}";
            enabled = true;
            alerts = [ { type = "matrix"; } ];
            interval = "5m";
            conditions = [ "[STATUS] == 200" ];
          }
        ];

        # --- caddy ---

        # no proxy-auth - silo has built-in auth
        services.caddy.virtualHosts.${localHost}.extraConfig = ''
          reverse_proxy ${listenUrl} {
            flush_interval -1
          }
        '';
      }
      // lib.optionalAttrs (options ? preservation) {
        preservation.preserveAt."/persist".directories = [
          {
            directory = dataDir;
            user = "silo";
            group = "silo";
          }
        ];
      };
    };
}
