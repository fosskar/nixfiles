{
  flake.modules.nixos.grafana =
    {
      nflib,
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
      smtpEnabled = config.clan.core.vars.generators ? smtp;

    in
    {
      config = lib.mkIf config.services.grafana.enable {
        # --- secrets ---

        clan.core.vars.generators.grafana = {
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
          files."oauth-client-secret-hash" = {
            owner = "authelia-main";
            group = "authelia-main";
          };

          runtimeInputs = [
            pkgs.pwgen
            pkgs.openssl
            pkgs.authelia
          ];
          script = ''
            ADMIN_PASSWORD=$(openssl rand -hex 32)
            SECRET=$(pwgen -s 64 1)
            SECRET_KEY=$(openssl rand -hex 32)
            echo -n "$ADMIN_PASSWORD" > "$out/admin-password"
            authelia crypto hash generate pbkdf2 --password "$SECRET" | tail -1 | cut -d' ' -f2 > "$out/oauth-client-secret-hash"
            echo -n "$SECRET" > "$out/oauth-client-secret"
            echo -n "$SECRET_KEY" > "$out/secret-key"
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
            authorization_policy = "admins";
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
            grant_types = [ "authorization_code" ];
            token_endpoint_auth_method = "client_secret_basic";
            id_token_signed_response_alg = "RS256";
            claims_policy = "grafana_groups";
          }
        ];

        # --- service ---

        systemd.services.grafana.serviceConfig.EnvironmentFile = lib.mkIf smtpEnabled [
          config.clan.core.vars.generators.smtp.files."smtp-env".path
        ];

        services.grafana = {
          openFirewall = false;

          declarativePlugins = [
            pkgs.grafanaPlugins.victoriametrics-metrics-datasource
            pkgs.grafanaPlugins.victoriametrics-logs-datasource
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

            smtp = lib.mkIf smtpEnabled {
              enabled = true;
              host = "$__env{SMTP_HOST}:$__env{SMTP_PORT}";
              user = "$__env{SMTP_USER}";
              password = "$__env{SMTP_PASSWORD}";
              from_address = "$__env{SMTP_FROM}";
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

            "auth.anonymous" = {
              enabled = true;
              org_name = "Main Org.";
              org_role = "Viewer";
              hide_version = true;
            };

            "auth.generic_oauth" = {
              enabled = true;
              name = "Authelia";
              use_refresh_token = false;
              icon = "signin";
              allow_sign_up = true;
              #auto_login = true;
              client_id = "grafana";
              client_secret = "$__file{${
                config.clan.core.vars.generators.grafana.files."oauth-client-secret".path
              }}";
              scopes = "openid profile email groups";
              auth_url = "https://auth.${config.domains.local}/api/oidc/authorization";
              token_url = "https://auth.${config.domains.local}/api/oidc/token";
              api_url = "https://auth.${config.domains.local}/api/oidc/userinfo";
              signout_redirect_url = "https://auth.${config.domains.local}/logout";
              auth_style = "InHeader";
              use_pkce = true;
              login_attribute_path = "preferred_username";
              name_attribute_path = "name";
              groups_attribute_path = "groups";
              role_attribute_path = builtins.concatStringsSep " || " [
                "contains(groups, 'admin') && 'GrafanaAdmin'"
                "'None'"
              ];
              role_attribute_strict = true;
              allow_assign_grafana_admin = true;
              skip_org_role_sync = false;
            };
          };
        };

        # --- alerting ---

        services.grafana.provision.alerting = lib.mkIf smtpEnabled {
          contactPoints.settings = {
            apiVersion = 1;
            contactPoints = [
              {
                orgId = 1;
                name = "mailbox";
                receivers = [
                  {
                    uid = "mailbox-email";
                    type = "email";
                    settings.addresses = "grafana@nx3.eu";
                  }
                ];
              }
            ];
          };
          policies.settings = {
            apiVersion = 1;
            policies = [
              {
                orgId = 1;
                receiver = "mailbox";
                group_by = [
                  "grafana_folder"
                  "alertname"
                ];
              }
            ];
          };
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
          (nflib.gatusEndpoint {
            name = "Grafana";
            url = "https://${localHost}";
            group = "Monitoring";
          })
        ];

        # --- caddy ---

        services.caddy.virtualHosts.${localHost}.extraConfig = ''
          reverse_proxy ${listenUrl}
        '';
      };
    };
}
