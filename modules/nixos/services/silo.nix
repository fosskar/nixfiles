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
      # jellyfin has 8096
      jellyfinPort = 8196;
      jellyfinHost = "silo-jellyfin.${flake-self.domains.local}";
      dataDir = "/var/lib/silo";
      mediaRoot = "/tank/media";
      redis = config.services.redis.servers.silo;
      apiUrl = "${listenUrl}/api/v2";
      generators = config.clan.core.vars.generators;
      # the deployment document reads secrets as silo from these credentials
      credentialsDir = "/run/credentials/silo.service";
      settingsFormat = pkgs.formats.json { };
      # catalog search moves to the meilisearch feature when this host has it
      meilisearch = config.services.meilisearch;
      llamaCpp = config.services.llama-cpp.settings;
      embeddingModel = "qwen3-embedding-0.6b";
      # embeds library items for recommendations
      aiProvider = "llama-cpp";
      # translates subtitles. the local model took 46 s for a batch of 40 lines;
      # the openrouter key's guardrail allows only this model alias and only
      # zero-retention endpoints of river and inceptron, which run in finland
      # and iceland. the alias follows new deepseek flash versions: if neither
      # provider hosts one yet, translations fail until the model is pinned
      # here and in the guardrail. reasoning effort is "low": with "none" the
      # model dropped lines of a 40-line batch three times and the job failed
      textProvider = "openrouter";
      chatModel = "~deepseek/deepseek-flash-latest";
      # writes subtitles from audio; whisper.cpp on the arc gpu in nixworker
      speechProvider = "whisper-cpp";
      requestsPlugin = "silo.requests.arr";
      autoscanPlugin = "silo.autoscan.arr";
      # requests go to the sonarr and radarr of the arr-stack feature, with
      # the profiles and folders seerr used
      requestIntegrations = {
        sonarr = {
          port = 8989;
          mediaType = "series";
          qualityProfile = "WEB-1080p";
          config = {
            service_kind = "sonarr";
            root_folder = "${mediaRoot}/tv";
            is_default = true;
            search_on_add = true;
            monitor = "all";
            series_type = "standard";
            season_folder = true;
          };
        };
        radarr = {
          port = 7878;
          mediaType = "movie";
          qualityProfile = "Remux + WEB 1080p";
          config = {
            service_kind = "radarr";
            root_folder = "${mediaRoot}/movies";
            is_default = true;
            search_on_add = true;
            minimum_availability = "inCinemas";
          };
        };
      };
      arrKeyUnits = map (name: "${name}-api.service") (lib.attrNames requestIntegrations);
    in
    {
      options.services.silo.settings = lib.mkOption {
        inherit (settingsFormat) type;
        default = { };
        description = ''
          silo deployment document, passed as SILO_CONFIG_FILE. it declares
          official plugins and ai providers; give secrets as
          `{ fromFile = "<path>"; }`. see
          https://github.com/Silo-Server/silo-server/blob/main/contracts/plugins/provisioning/v1/schema.json
        '';
      };

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

        clan.core.vars.generators.silo-meilisearch = lib.mkIf meilisearch.enable {
          dependencies = [ "meilisearch-master" ];
          files."meilisearch.env".restartUnits = [ "silo.service" ];
          script = ''
            echo "SILO_MEILISEARCH_API_KEY=$(${flake-self.meilisearch.tenantKey pkgs "silo"})" > "$out/meilisearch.env"
          '';
        };

        # silo reads SILO_SMTP_*; the shared smtp-env names them SMTP_*
        clan.core.vars.generators.silo-smtp = {
          dependencies = [ "smtp" ];
          files."smtp.env".restartUnits = [ "silo.service" ];
          runtimeInputs = [ pkgs.gnused ];
          script = ''
            sed -n \
              -e 's/^SMTP_HOST=/SILO_SMTP_HOST=/p' \
              -e 's/^SMTP_PORT=/SILO_SMTP_PORT=/p' \
              -e 's/^SMTP_USER=/SILO_SMTP_USER=/p' \
              -e 's/^SMTP_PASSWORD=/SILO_SMTP_PASSWORD=/p' \
              -e 's/^SMTP_FROM=/SILO_SMTP_FROM_ADDRESS=/p' \
              "$in/smtp/smtp-env" > "$out/smtp.env"
          '';
        };

        services.redis.servers.silo.enable = true;

        services.silo.settings = {
          apiVersion = 1;
          # unpinned, so silo keeps updating them
          plugins = {
            "silo.tmdb" = { };
            "silo.tvdb" = { };
            "silo.theintrodb" = { };
            "silo.auth.oidc" = {
              config = {
                connection = {
                  issuer_url = "https://auth.${flake-self.domains.public}";
                  client_id = "silo";
                  client_secret.fromFile = "${credentialsDir}/oidc-client-secret";
                  request_groups_scope = true;
                };
                display_name.value = "Authelia";
                access.admin_groups = "admin";
              };
              auth_binding = {
                capability_id = "oidc";
                enabled = true;
                display_order = 0;
                default_login = false;
                auto_provision = true;
                # <public url>/api/v2/auth/oauth/callback, without the installation id
                callback = "stable";
              };
            };
            # silo polls sonarr and radarr for imports and rescans those paths
            "${autoscanPlugin}" = { };
            # ratings: tmdb only has its own score. mdblist adds imdb and
            # rotten tomatoes to titles the other providers matched; a fresh
            # install places it after them in the movie and series chains
            "silo.mdblist".config.account.api_key.fromFile = "${credentialsDir}/mdblist-api-key";
          };
          ai_providers = {
            ${aiProvider} = {
              type = "custom";
              # silo refuses a name another provider id has; "llama-cpp" is the
              # provider silo-sync used to create on nixbox
              name = "llama.cpp";
              base_url = "http://${llamaCpp.host}:${toString llamaCpp.port}";
              capabilities = [
                "chat"
                "embeddings"
              ];
            };
            # the capabilities of whisper and openrouter providers are fixed
            ${speechProvider} = {
              type = "whisper";
              name = "whisper.cpp";
              base_url = flake-self.whisperServer.url;
            };
            ${textProvider} = {
              type = "openrouter";
              api_key.fromFile = "${credentialsDir}/openrouter-api-key";
            };
          };
        };

        systemd.services.silo = {
          description = "silo media server";
          after = [
            "network-online.target"
            "postgresql.service"
            "redis-silo.service"
            "silo-postgresql-extensions.service"
          ]
          ++ lib.optional meilisearch.enable "meilisearch-keys.service";
          # wants, not requires: silo searches postgres while meilisearch is down
          wants = [ "network-online.target" ] ++ lib.optional meilisearch.enable "meilisearch-keys.service";
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
            JF_PORT = toString jellyfinPort;
            # audiobookshelf has 13378
            ABS_PORT = "13379";
            DATABASE_URL = "postgres://silo@/silo?host=/run/postgresql&sslmode=disable";
            REDIS_URL = "unix://${redis.unixSocket}";
            SILO_PLUGIN_CACHE_DIR = "${dataDir}/plugins";
            HOME = dataDir;
            # settings set here are stored at startup and read-only in the admin ui
            SILO_PUBLIC_URL = "https://${localHost}";
            SILO_JELLYFIN_PUBLIC_URL = "https://${jellyfinHost}";
            SILO_SMTP_ENABLED = "true";
            # port 587 is starttls
            SILO_SMTP_SECURITY = "starttls";
            SILO_CONFIG_FILE = settingsFormat.generate "silo-config.json" config.services.silo.settings;
            SILO_RECOMMENDATIONS_ENABLED = "true";
            SILO_RECOMMENDATIONS_PROVIDER = aiProvider;
            SILO_RECOMMENDATIONS_MODEL = embeddingModel;
          }
          // lib.optionalAttrs meilisearch.enable {
            SILO_SEARCH_PROVIDER = "meilisearch";
            SILO_MEILISEARCH_URL = "http://${meilisearch.listenAddress}:${toString meilisearch.listenPort}";
          };
          serviceConfig = {
            User = "silo";
            Group = "silo";
            StateDirectory = "silo";
            WorkingDirectory = dataDir;
            EnvironmentFile = [
              generators.silo.files."secret.env".path
              generators.silo-smtp.files."smtp.env".path
            ]
            ++ lib.optional meilisearch.enable generators.silo-meilisearch.files."meilisearch.env".path;
            LoadCredential = [
              "oidc-client-secret:${generators.silo-oidc.files."oauth-client-secret".path}"
              "mdblist-api-key:${generators.silo-mdblist.files.api-key.path}"
              "openrouter-api-key:${generators.silo-openrouter.files.api-key.path}"
            ];
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
            description = "silo admin api key (https://silo.nx3.eu/admin/api-keys, full access)";
            type = "hidden";
            persist = true;
          };
          files.api-key.restartUnits = [ "silo-sync.service" ];
        };

        clan.core.vars.generators.silo-openrouter = {
          prompts.api-key = {
            description = "openrouter api key for silo (https://openrouter.ai/settings/keys)";
            type = "hidden";
            persist = true;
          };
          files.api-key.restartUnits = [ "silo.service" ];
        };

        clan.core.vars.generators.silo-mdblist = {
          prompts.api-key = {
            description = "mdblist api key (https://mdblist.com/preferences/#api)";
            type = "hidden";
            persist = true;
          };
          files.api-key.restartUnits = [ "silo.service" ];
        };

        clan.core.vars.generators.silo-oidc = {
          files = {
            "oauth-client-secret-hash" = {
              owner = "authelia-main";
              group = "authelia-main";
            };
            "oauth-client-secret".restartUnits = [ "silo.service" ];
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
            redirect_uris = [ "https://${localHost}/api/v2/auth/oauth/callback" ];
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
          after = [ "silo.service" ] ++ arrKeyUnits;
          requires = [ "silo.service" ] ++ arrKeyUnits;
          wantedBy = [ "multi-user.target" ];
          serviceConfig = {
            SupplementaryGroups = map (name: "${name}-api") (lib.attrNames requestIntegrations);
            Type = "oneshot";
            RemainAfterExit = true;
            DynamicUser = true;
            LoadCredential = [ "api-key:${generators.silo-api.files.api-key.path}" ];
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

              # --retry: an api key is limited to 20 requests a second, and
              # silo answers 429 above that
              api() {
                method=$1
                path=$2
                shift 2
                curl -sfS --retry 5 -X "$method" -H @/tmp/api-key.header -H 'Content-Type: application/json' "$@" "$base$path"
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

              # the deployment document's plugins install after the listener starts
              for _ in $(seq 150); do
                status=$(api GET /admin/plugins/provisioning-status)
                if jq -e 'all(.items[]; .state != "pending")' <<<"$status" >/dev/null; then
                  break
                fi
                sleep 2
              done
              # "held" is a plugin an administrator disabled
              failed=$(jq -r '.items[] | select(.state == "pending" or .state == "refused") | "\(.plugin_id): \(.state) \(.detail)"' <<<"$status")
              if [ -n "$failed" ]; then
                echo "$failed" >&2
                exit 1
              fi

              # prints the installation id of a plugin, installing it when missing
              plugin() {
                id=$(api GET /admin/plugins/installations \
                  | jq -r --arg plugin "$1" '.items[] | select(.plugin_id == $plugin) | .id')
                if [ -z "$id" ]; then
                  id=$(api GET /admin/plugins/catalog \
                    | jq -ce --arg plugin "$1" '.items[] | select(.plugin_id == $plugin) | {plugin_id, repository_id, version}' \
                    | api POST /admin/plugins/installations --data-binary @- | jq -re .id)
                  echo "installed $1 as installation $id" >&2
                fi
                if [ -z "$id" ]; then
                  echo "plugin $1 is not in the catalog" >&2
                  return 1
                fi
                printf '%s' "$id"
              }

              # requests: the router plugin is in the approved community catalog
              api PUT /admin/plugins/catalog-settings -H 'If-Match: *' \
                --data-binary '{"include_approved_community_plugins": true}' >/dev/null
              router=$(plugin ${requestsPlugin})

              # upserts one request integration by name. the quality profile id
              # is looked up by name, because the id differs per install
              integration() {
                name=$1
                jq -n --arg installation "$router" --arg name "$name" --arg url "$2" \
                  --rawfile key "/run/arr-api-keys/$name/api-key" '{
                    installation_id: $installation,
                    capability_id: "arr",
                    name: $name,
                    base_url: $url,
                    api_key_ref: $key,
                    plugin_config: {}
                  }' > /tmp/integration.json
                profile=$(api POST /admin/request-integrations/new/options --data-binary @/tmp/integration.json \
                  | jq -re --arg profile "$4" '.options.quality_profile_id[] | select(.label == $profile) | .value | tonumber')
                jq --arg media "$3" --argjson profile "$profile" --argjson config "$5" '. + {
                  supported_media_types: [$media],
                  enabled: true,
                  plugin_config: ($config + {quality_profile_id: $profile})
                }' /tmp/integration.json > /tmp/integration-body.json
                id=$(api GET /admin/request-integrations \
                  | jq -r --arg name "$name" '.items[] | select(.name == $name) | .id')
                if [ -n "$id" ]; then
                  api PUT "/admin/request-integrations/$id" -H 'If-Match: *' --data-binary @/tmp/integration-body.json >/dev/null
                else
                  api POST /admin/request-integrations --data-binary @/tmp/integration-body.json >/dev/null
                fi
                echo "synced request integration $name"
              }
              ${lib.concatStringsSep "\n" (
                lib.mapAttrsToList (
                  name: integration:
                  "integration ${name} http://127.0.0.1:${toString integration.port} ${integration.mediaType} ${lib.escapeShellArg integration.qualityProfile} ${lib.escapeShellArg (builtins.toJSON integration.config)}"
                ) requestIntegrations
              )}

              api GET /admin/request-settings \
                | jq -c '. + {requests_enabled: true, global_auto_approval_enabled: true}' \
                | api PUT /admin/request-settings -H 'If-Match: *' --data-binary @- >/dev/null
              echo "enabled requests"

              # autoscan reads sonarr and radarr through the request
              # integrations' credentials
              autoscan() {
                name=$1
                connection=$(api GET /admin/autoscan/connections \
                  | jq -r --arg name "$name" '.items[] | select(.name == $name) | .id')
                if [ -z "$connection" ]; then
                  connection=$(api GET /admin/request-integrations \
                    | jq -ce --arg name "$name" '.items[] | select(.name == $name)
                        | {name: $name, kind: $name, request_integration_id: .id}' \
                    | api POST /admin/autoscan/connections --data-binary @- | jq -re .id)
                fi
                source=$(jq -nc --arg name "$name" --arg connection "$connection" '{
                  label: $name,
                  connection_id: $connection,
                  delivery_mode: "poll",
                  poll_interval_seconds: 60,
                  enabled: true,
                  path_rewrites: []
                }')
                id=$(api GET /admin/autoscan/sources \
                  | jq -r --arg name "$name" '.items[] | select(.label == $name) | .id')
                if [ -n "$id" ]; then
                  api PUT "/admin/autoscan/sources/$id" -H 'If-Match: *' --data-binary "$source" >/dev/null
                else
                  jq -c '. + {plugin_id: "${autoscanPlugin}", capability_id: "arr"}' <<<"$source" \
                    | api POST /admin/autoscan/sources --data-binary @- >/dev/null
                fi
                echo "synced autoscan source $name"
              }
              ${lib.concatMapStringsSep "\n" (name: "autoscan ${name}") (lib.attrNames requestIntegrations)}
              api GET /admin/autoscan/settings | jq -c '.enabled = true' \
                | api PUT /admin/autoscan/settings -H 'If-Match: *' --data-binary @- >/dev/null
              echo "enabled autoscan"

              # no environment variables exist for these
              result=$(jq -n '{
                values: {
                  "catalog.extra_rating_sources": "rt_critic",
                  ${lib.optionalString meilisearch.enable ''"catalog.search.meilisearch.semantic_enabled": "true",''}
                  "subtitle_ai.enabled": "true",
                  "subtitle_ai.transcribe_enabled": "true",
                  "ai.speech_provider_id": "${speechProvider}",
                  "ai.asr_model": "${flake-self.whisperServer.model}",
                  "ai.text_provider_id": "${textProvider}",
                  "ai.chat_model": "${chatModel}",
                  "ai.reasoning_effort": "low",
                  "ai.max_concurrent_jobs": "2"
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
                  icon = "https://${localHost}/web-app-icon-192.png";
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

        # jellyfin clients such as streamyfin connect here
        services.caddy.virtualHosts.${jellyfinHost}.extraConfig = ''
          reverse_proxy http://127.0.0.1:${toString jellyfinPort} {
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
