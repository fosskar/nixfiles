{
  flake.modules.nixos.opencloud =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      dataDir = config.services.opencloud.environment.STORAGE_USERS_POSIX_ROOT;
      serviceName = "opencloud";
      localHost = "${serviceName}.${config.domains.local}";
      publicHost = "${serviceName}.${config.domains.public}";
      listenAddress = "0.0.0.0";
      listenPort = 9200;
      webListenPort = 9201;
      listenUrl = "http://127.0.0.1:${toString listenPort}";
      oidcIssuerUrl = "https://auth.${config.domains.public}";

      publicHostUris = [
        "https://${publicHost}/"
        "https://${publicHost}/oidc-callback.html"
        "https://${publicHost}/oidc-silent-redirect.html"
        "https://${publicHost}/web-oidc-callback"
      ];

      oidcOrigins = [
        "https://auth.${config.domains.local}"
        "https://auth.${config.domains.public}"
      ];

      settingsFormat = pkgs.formats.yaml { };

      commonClientConfig = {
        public = true;
        consent_mode = "implicit";
        authorization_policy = "users";
        scopes = [
          "openid"
          "profile"
          "email"
          "groups"
        ];
        response_types = [ "code" ];
        grant_types = [
          "authorization_code"
          "refresh_token"
        ];
        token_endpoint_auth_method = "none";
      };

      radicaleRoute = endpoint: scriptName: {
        inherit endpoint;
        backend = "http://127.0.0.1:5232";
        remote_user_header = "X-Remote-User";
        skip_x_access_token = true;
        additional_headers = [ { "X-Script-Name" = scriptName; } ];
      };

      cspConfig = {
        directives = {
          connect-src = oidcOrigins;
          frame-src = oidcOrigins;
        };
      };
    in
    {
      config = {
        clan.core.vars.generators.opencloud = {
          files = {
            "admin-password" = { };
            "envfile" = {
              secret = true;
              owner = "opencloud";
              group = "opencloud";
            };
          };
          runtimeInputs = [
            pkgs.pwgen
            pkgs.util-linux
          ];
          script = ''
            password=$(pwgen -s 32 1 | tr -d '\n')
            service_account_id=$(uuidgen)
            service_account_secret=$(pwgen -s 32 1 | tr -d '\n')
            printf "%s" "$password" > "$out/admin-password"
            printf "ADMIN_PASSWORD=%s\nIDM_ADMIN_PASSWORD=%s\nOC_SERVICE_ACCOUNT_ID=%s\nOC_SERVICE_ACCOUNT_SECRET=%s\n" \
              "$password" "$password" "$service_account_id" "$service_account_secret" > "$out/envfile"
          '';
        };

        services.authelia.instances.main.settings.identity_providers.oidc.cors = {
          allowed_origins_from_client_redirect_uris = true;
          endpoints = [
            "authorization"
            "token"
            "userinfo"
            "revocation"
          ];
        };

        services.authelia.instances.main.settings.identity_providers.oidc.clients = [
          (
            commonClientConfig
            // {
              client_id = "web";
              client_name = "OpenCloud Web";
              redirect_uris = [
                "https://${localHost}/"
                "https://${localHost}/oidc-callback.html"
                "https://${localHost}/oidc-silent-redirect.html"
                "https://${localHost}/web-oidc-callback"
              ]
              ++ publicHostUris;
            }
          )
          (
            commonClientConfig
            // {
              client_id = "OpenCloudDesktop";
              client_name = "OpenCloud Desktop";
              redirect_uris = [
                "http://127.0.0.1"
                "http://localhost"
              ];
            }
          )
          (
            commonClientConfig
            // {
              client_id = "OpenCloudAndroid";
              client_name = "OpenCloud Android";
              redirect_uris = [ "oc://android.opencloud.eu" ];
            }
          )
          (
            commonClientConfig
            // {
              client_id = "OpenCloudIOS";
              client_name = "OpenCloud iOS";
              redirect_uris = [ "oc://ios.opencloud.eu" ];
            }
          )
        ];

        services.tika = {
          enable = true;
          enableOcr = true;
          listenAddress = "127.0.0.1";
          port = 9998;
        };

        services.opencloud = {
          enable = true;
          package = pkgs.custom.opencloud;
          url = "https://${localHost}";
          address = listenAddress;
          environmentFile = config.clan.core.vars.generators.opencloud.files."envfile".path;
          port = listenPort;

          environment = {
            PROXY_TLS = "false";
            WEB_HTTP_ADDR = "127.0.0.1:${toString webListenPort}";
            OC_INSECURE = "true";
            OC_LOG_LEVEL = "warn";
            PROXY_CSP_CONFIG_FILE_LOCATION = "${settingsFormat.generate "csp.yaml" cspConfig}";

            OC_OIDC_ISSUER = oidcIssuerUrl;
            OC_EXCLUDE_RUN_SERVICES = "idp";
            PROXY_AUTOPROVISION_ACCOUNTS = "true";

            PROXY_OIDC_ACCESS_TOKEN_VERIFY_METHOD = "none";
            PROXY_OIDC_USERINFO_CACHE_TTL = "10m";
            GRAPH_SPACES_DEFAULT_QUOTA = "107374182400"; # 100GB
            PROXY_USER_OIDC_CLAIM = "sub";
            PROXY_USER_CS3_CLAIM = "userid";
            GRAPH_USERNAME_MATCH = "none";
            WEB_OPTION_ACCOUNT_EDIT_LINK = "https://auth.${config.domains.public}/settings";

            STORAGE_USERS_POSIX_ROOT = lib.mkDefault "/tank/apps/opencloud/data";
            STORAGE_USERS_POSIX_WATCH_FS = "true";
            STORAGE_USERS_POSIX_USE_SPACE_GROUPS = "true";

            SEARCH_EXTRACTOR_TYPE = "tika";
            SEARCH_EXTRACTOR_TIKA_TIKA_URL = "http://127.0.0.1:${toString config.services.tika.port}";
            SEARCH_EVENTS_NUM_CONSUMERS = "2";
            FRONTEND_FULL_TEXT_SEARCH_ENABLED = "true";
          };

          settings = {
            proxy = {
              oidc.rewrite_well_known = true;
              additional_policies = [
                {
                  name = "default";
                  routes = [
                    (radicaleRoute "/caldav/" "/caldav")
                    (radicaleRoute "/.well-known/caldav" "/caldav")
                    (radicaleRoute "/carddav/" "/carddav")
                    (radicaleRoute "/.well-known/carddav" "/carddav")
                  ];
                }
              ];
            };
            web.web.config.oidc = {
              authority = oidcIssuerUrl;
              client_id = "web";
              scope = "openid profile email groups";
            };
          };
        };

        services.homepage-dashboard.serviceGroups."Files" =
          lib.mkIf config.services.homepage-dashboard.enable
            [
              {
                "OpenCloud" = {
                  href = "https://${localHost}";
                  icon = "https://${localHost}/themes/opencloud/assets/favicon.svg";
                  siteMonitor = listenUrl;
                };
              }
            ];

        services.gatus.settings.endpoints = lib.mkIf config.services.gatus.enable [
          {
            name = "OpenCloud";
            url = "https://${localHost}";
            group = "Files";
            enabled = true;
            interval = "5m";
            conditions = [ "[STATUS] == 200" ];
            alerts = [ { type = "email"; } ];
          }
        ];

        services.caddy.virtualHosts.${localHost}.extraConfig = ''
          reverse_proxy ${listenUrl} {
            flush_interval -1
            transport http {
              read_timeout 3600s
              write_timeout 3600s
            }
          }
          request_body {
            max_size 10GB
          }
        '';

        clan.core.state.opencloud.folders = [ "/var/lib/opencloud" ];

        preservation.preserveAt."/persist".directories = [
          {
            directory = "/var/lib/opencloud";
            user = "opencloud";
            group = "opencloud";
          }
        ];

        systemd.services.opencloud = {
          after = [ "tika.service" ];
          wants = [ "tika.service" ];
          serviceConfig.ReadWritePaths = [ dataDir ];
          path = [ pkgs.inotify-tools ];
        };

        systemd.tmpfiles.settings."10-opencloud-data" = {
          ${dataDir}.d = {
            user = "opencloud";
            group = "opencloud";
            mode = "0750";
          };
        };

        systemd.services.opencloud-permission-fixer = {
          description = "fix opencloud file permissions for group access";
          after = [ "opencloud.service" ];
          requires = [ "opencloud.service" ];
          wantedBy = [ "multi-user.target" ];
          path = [
            pkgs.inotify-tools
            pkgs.coreutils
            pkgs.findutils
          ];
          serviceConfig = {
            Type = "simple";
            User = "opencloud";
            Group = "opencloud";
            Restart = "always";
            RestartSec = 5;
            ExecStart = pkgs.writeShellScript "opencloud-permission-fixer" ''
              ${pkgs.inotify-tools}/bin/inotifywait -m -r -e create,moved_to --format '%w%f' "${dataDir}" | while read -r path; do
                if [ -f "$path" ]; then
                  chmod g+rw "$path"
                elif [ -d "$path" ]; then
                  chmod g+rwx "$path"
                fi
              done
            '';
          };
        };
      };
    };
}
