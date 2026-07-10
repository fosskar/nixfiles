{
  flake.modules.nixos.opencloud =
    {
      flake-self,
      config,
      lib,
      options,
      pkgs,
      ...
    }:
    let
      dataDir = config.services.opencloud.environment.STORAGE_USERS_POSIX_ROOT;
      serviceName = "opencloud";
      localHost = "${serviceName}.${flake-self.domains.local}";
      publicHost = "${serviceName}.${flake-self.domains.public}";
      listenAddress = "0.0.0.0";
      listenPort = 9200;
      webListenPort = 9201;
      listenUrl = "http://127.0.0.1:${toString listenPort}";
      oidcIssuerUrl = "https://auth.${flake-self.domains.public}";

      publicHostUris = [
        "https://${publicHost}/"
        "https://${publicHost}/oidc-callback.html"
        "https://${publicHost}/oidc-silent-redirect.html"
        "https://${publicHost}/web-oidc-callback"
      ];

      oidcOrigins = [
        "https://auth.${flake-self.domains.local}"
        "https://auth.${flake-self.domains.public}"
      ];

      settingsFormat = pkgs.formats.yaml { };

      commonClientConfig = {
        public = true;
        # offline_access forces explicit consent regardless of consent_mode, so
        # use pre-configured consent to remember it instead of prompting every time.
        consent_mode = "pre-configured";
        pre_configured_consent_duration = "1y";
        # extend refresh-token lifespan (default 90m) so idle native clients keep
        # their session; scoped to opencloud via the custom lifespan profile below.
        lifespan = "opencloud";
        authorization_policy = "users";
        claims_policy = "opencloud_groups";
        require_pkce = true;
        pkce_challenge_method = "S256";
        scopes = [
          "openid"
          "profile"
          "email"
          "groups"
          "offline_access"
        ];
        response_types = [ "code" ];
        grant_types = [
          "authorization_code"
          "refresh_token"
        ];
        token_endpoint_auth_method = "none";
      };

      # merged into upstream defaults by the proxy (deepMerge, lists concatenated),
      # so only additions need listing here. stays in this file because
      # PROXY_CSP_CONFIG_FILE_LOCATION is a single generated file.
      cspConfig = {
        directives = {
          connect-src = oidcOrigins;
          frame-src = oidcOrigins ++ [ "https://collabora.${flake-self.domains.local}" ];
        };
      };

      # web extensions for WEB_ASSET_APPS_PATH; restart to pick up changes
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

        services.authelia.instances.main.settings.identity_providers.oidc = {
          lifespans.custom.opencloud.refresh_token = "1y";
          claims_policies.opencloud_groups = {
            id_token = [ "groups" ];
            access_token = [ "groups" ];
            custom_claims.groups.attribute = "groups";
          };
          cors = {
            allowed_origins_from_client_redirect_uris = true;
            endpoints = [
              "authorization"
              "token"
              "userinfo"
              "revocation"
            ];
          };
        };

        services.authelia.instances.main.settings.identity_providers.oidc.clients = [
          (
            commonClientConfig
            // {
              client_id = "OpenCloudWeb";
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
          # tika defaults to language=eng at runtime; include german models for
          # proper umlaut/ß recognition in scanned documents
          configFile = pkgs.writeText "tika-config.xml" ''
            <properties>
              <parsers>
                <parser class="org.apache.tika.parser.DefaultParser">
                  <parser-exclude class="org.apache.tika.parser.ocr.TesseractOCRParser"/>
                </parser>
                <parser class="org.apache.tika.parser.ocr.TesseractOCRParser">
                  <params>
                    <param name="language" type="string">deu+eng</param>
                  </params>
                </parser>
              </parsers>
            </properties>
          '';
          listenAddress = "127.0.0.1";
          port = 9998;
        };

        services.opencloud = {
          enable = true;
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
            #WEB_ASSET_APPS_PATH = "${webApps}";
            OC_EXCLUDE_RUN_SERVICES = "idp";
            PROXY_AUTOPROVISION_ACCOUNTS = "true";

            PROXY_OIDC_ACCESS_TOKEN_VERIFY_METHOD = "none";
            PROXY_OIDC_USERINFO_CACHE_TTL = "10m";
            GRAPH_SPACES_DEFAULT_QUOTA = "107374182400"; # 100GB
            PROXY_USER_OIDC_CLAIM = "sub";
            PROXY_AUTOPROVISION_CLAIM_USERNAME = "preferred_username";
            PROXY_AUTOPROVISION_CLAIM_EMAIL = "email";
            PROXY_AUTOPROVISION_CLAIM_DISPLAYNAME = "name";
            PROXY_AUTOPROVISION_CLAIM_GROUPS = "groups";
            # match authelia's stable sub uuid against opencloud's immutable userid,
            # so the displayed username (provisioned from preferred_username) stays pretty.
            PROXY_USER_CS3_CLAIM = "userid";
            PROXY_ROLE_ASSIGNMENT_DRIVER = "oidc";
            PROXY_ROLE_ASSIGNMENT_OIDC_CLAIM = "groups";
            GRAPH_ASSIGN_DEFAULT_USER_ROLE = "false";
            GRAPH_USERNAME_MATCH = "none";
            WEBFINGER_WEB_OIDC_CLIENT_ID = "OpenCloudWeb";
            WEBFINGER_WEB_OIDC_CLIENT_SCOPES = "openid profile email groups";
            WEBFINGER_DESKTOP_OIDC_CLIENT_ID = "OpenCloudDesktop";
            WEBFINGER_DESKTOP_OIDC_CLIENT_SCOPES = "openid profile email groups offline_access";
            WEBFINGER_ANDROID_OIDC_CLIENT_ID = "OpenCloudAndroid";
            WEBFINGER_ANDROID_OIDC_CLIENT_SCOPES = "openid profile email groups offline_access";
            WEBFINGER_IOS_OIDC_CLIENT_ID = "OpenCloudIOS";
            WEBFINGER_IOS_OIDC_CLIENT_SCOPES = "openid profile email groups offline_access";
            WEB_OPTION_ACCOUNT_EDIT_LINK = "https://auth.${flake-self.domains.public}/settings";

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
              role_assignment = {
                driver = "oidc";
                oidc_role_mapper = {
                  role_claim = "groups";
                  role_mapping = [
                    {
                      role_name = "admin";
                      claim_value = "admin";
                    }
                    {
                      role_name = "user";
                      claim_value = "user";
                    }
                  ];
                };
              };
            };
            web.web.config.oidc = {
              authority = oidcIssuerUrl;
              client_id = "OpenCloudWeb";
              scope = "openid profile email groups offline_access";
            };
          };
        };

        services.homepage-dashboard.services = [
          {
            "files" = [
              {
                "OpenCloud" = {
                  href = "https://${localHost}";
                  icon = "https://${localHost}/themes/opencloud/assets/favicon.svg";
                  siteMonitor = listenUrl;
                };
              }
            ];
          }
        ];

        services.gatus.settings.endpoints = [
          {
            name = "OpenCloud";
            url = "https://${localHost}";
            group = "Files";
            enabled = true;
            alerts = [ { type = "email"; } ];
            interval = "5m";
            conditions = [ "[STATUS] == 200" ];
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

        clan.core.state.opencloud.folders = [
          "/etc/opencloud"
          "/var/lib/opencloud"
        ];

        systemd.services.opencloud = {
          after = [ "tika.service" ];
          wants = [ "tika.service" ];
          unitConfig.RequiresMountsFor = [ dataDir ];
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
          unitConfig.RequiresMountsFor = [ dataDir ];
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
      }
      // lib.optionalAttrs (options ? preservation) {
        preservation.preserveAt."/persist".directories = [
          "/etc/opencloud"
          {
            directory = "/var/lib/opencloud";
            user = "opencloud";
            group = "opencloud";
          }
        ];
      };
    };
}
