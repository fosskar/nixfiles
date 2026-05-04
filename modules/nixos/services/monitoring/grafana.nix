{
  flake.modules.nixos.grafana =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      serviceName = "grafana";
      localHost = "${serviceName}.${config.domains.local}";
      listenAddress = "127.0.0.1";
      listenPort = 3100;
      listenUrl = "http://${listenAddress}:${toString listenPort}";
    in
    {
      config = lib.mkIf config.services.grafana.enable {
        # --- secrets ---

        clan.core.vars.generators.grafana = {
          prompts.smtp-email = {
            description = "gmail address for grafana smtp sender/login";
            persist = true;
          };
          prompts.smtp-password = {
            description = "gmail app password for grafana smtp";
            type = "hidden";
            persist = true;
          };

          files."admin-password" = {
            owner = "grafana";
            group = "grafana";
          };
          files."oauth-client-secret" = {
            owner = "grafana";
            group = "grafana";
          };
          files."secret-key" = {
            owner = "grafana";
            group = "grafana";
          };
          files."smtp-email" = {
            owner = "grafana";
            group = "grafana";
          };
          files."smtp-password" = {
            owner = "grafana";
            group = "grafana";
          };

          files."oauth-client-secret-hash" = {
            owner = "authelia-main";
            group = "authelia-main";
          };

          runtimeInputs = with pkgs; [
            pwgen
            openssl
            authelia
          ];
          script = ''
            ADMIN_PASSWORD=$(openssl rand -hex 32)
            SECRET=$(pwgen -s 64 1)
            SECRET_KEY=$(openssl rand -hex 32)
            SMTP_EMAIL=$(cat "$prompts/smtp-email")
            SMTP_PASSWORD=$(cat "$prompts/smtp-password")

            echo -n "$ADMIN_PASSWORD" > "$out/admin-password"
            authelia crypto hash generate pbkdf2 --password "$SECRET" | tail -1 | cut -d' ' -f2 > "$out/oauth-client-secret-hash"
            echo -n "$SECRET" > "$out/oauth-client-secret"
            echo -n "$SECRET_KEY" > "$out/secret-key"
            echo -n "$SMTP_EMAIL" > "$out/smtp-email"
            echo -n "$SMTP_PASSWORD" > "$out/smtp-password"
          '';
        };

        # --- oidc ---

        # claims policy to include groups in id_token for role mapping
        services.authelia.instances.main.settings.identity_providers.oidc.claims_policies.grafana_groups.id_token =
          [ "groups" ];

        services.authelia.instances.main.settings.identity_providers.oidc.clients = [
          {
            client_id = "grafana";
            client_name = "Grafana";
            client_secret = "{{ secret \"${
              config.clan.core.vars.generators.grafana.files."oauth-client-secret-hash".path
            }\" }}";
            public = false;
            consent_mode = "implicit";
            require_pkce = true;
            pkce_challenge_method = "S256";
            redirect_uris = [
              "https://${localHost}/login/generic_oauth"
            ];
            scopes = [
              "openid"
              "profile"
              "email"
              "groups"
            ];
            response_types = [ "code" ];
            grant_types = [
              "authorization_code"
            ];
            token_endpoint_auth_method = "client_secret_post";
            id_token_signed_response_alg = "RS256";
            claims_policy = "grafana_groups";
          }
        ];

        # --- service ---

        services.grafana = {
          openFirewall = false;

          declarativePlugins = with pkgs.grafanaPlugins; [
            victoriametrics-metrics-datasource
            victoriametrics-logs-datasource
          ];

          provision.dashboards.settings = {
            apiVersion = 1;
            providers = [
              {
                name = "nixos";
                orgId = 1;
                type = "file";
                disableDeletion = false;
                editable = true;
                options.path = "/etc/grafana-dashboards";
              }
            ];
          };

          settings = {
            server = {
              http_addr = listenAddress;
              http_port = listenPort;
              domain = localHost;
              root_url = "https://${localHost}";
              enable_gzip = true;
            };

            analytics = {
              reporting_enabled = false;
              check_for_updates = false;
            };

            security = {
              admin_user = "admin";
              cookie_secure = true;
              admin_password = "$__file{${config.clan.core.vars.generators.grafana.files."admin-password".path}}";
              secret_key = "$__file{${config.clan.core.vars.generators.grafana.files."secret-key".path}}";
            };

            smtp = {
              enabled = true;
              host = "smtp.gmail.com:587";
              user = "$__file{${config.clan.core.vars.generators.grafana.files."smtp-email".path}}";
              password = "$__file{${config.clan.core.vars.generators.grafana.files."smtp-password".path}}";
              from_address = "$__file{${config.clan.core.vars.generators.grafana.files."smtp-email".path}}";
              from_name = "grafana";
              ehlo_identity = localHost;
              startTLS_policy = "MandatoryStartTLS";
            };

            users = {
              allow_sign_up = false;
              auto_assign_org = true;
            };

            auth = {
              #oauth_auto_login = true;
              login_maximum_inactive_lifetime_duration = "30d";
              login_maximum_lifetime_duration = "30d";
            };

            "auth.generic_oauth" = {
              enabled = true;
              name = "Authelia";
              use_refresh_token = false;
              icon = "signin";
              #allow_sign_up = true;
              #auto_login = true;
              client_id = "grafana";
              client_secret = "$__file{${
                config.clan.core.vars.generators.grafana.files."oauth-client-secret".path
              }}";
              scopes = "openid profile email groups";
              auth_url = "https://auth.${config.domains.public}/api/oidc/authorization";
              token_url = "https://auth.${config.domains.public}/api/oidc/token";
              api_url = "https://auth.${config.domains.public}/api/oidc/userinfo";
              signout_redirect_url = "https://auth.${config.domains.public}/logout";
              use_pkce = true;
              login_attribute_path = "preferred_username";
              name_attribute_path = "name";
              groups_attribute_path = "groups";
              role_attribute_path = builtins.concatStringsSep " || " [
                "contains(groups, 'admin') && 'Admin'"
                "'Editor'"
              ];
              role_attribute_strict = false;
              allow_assign_grafana_admin = true;
              skip_org_role_sync = false;
            };
          };
        };

        # --- alerting ---

        services.grafana.provision.alerting.contactPoints.settings = {
          apiVersion = 1;
          deleteContactPoints = [
            #{
            #  orgId = 1;
            #  uid = "ntfy";
            #}
          ];
        };

        # --- homepage ---

        services.homepage-dashboard.serviceGroups."Monitoring" =
          lib.mkIf config.services.homepage-dashboard.enable
            [
              {
                "Grafana" = {
                  href = "https://${localHost}";
                  icon = "grafana.svg";
                  siteMonitor = listenUrl;
                };
              }
            ];

        # --- gatus ---

        services.gatus.settings.endpoints = lib.mkIf config.services.gatus.enable [
          {
            name = "Grafana";
            url = "https://${localHost}";
            group = "Monitoring";
            enabled = true;
            interval = "5m";
            conditions = [ "[STATUS] == 200" ];
            alerts = [ { type = "ntfy"; } ];
          }
        ];

        # --- caddy ---

        services.caddy.virtualHosts.${localHost}.extraConfig = ''
          reverse_proxy ${listenUrl}
        '';
      };
    };
}
