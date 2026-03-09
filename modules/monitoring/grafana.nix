{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.nixfiles.monitoring.grafana;
  acmeDomain = config.nixfiles.caddy.domain;
  inherit (config.nixfiles.authelia) publicDomain;
  serviceDomain = "grafana.${acmeDomain}";
  bindAddress = "127.0.0.1";
  port = 3100;
  internalUrl = "http://${bindAddress}:${toString port}";
in
{
  # --- options ---

  options.nixfiles.monitoring.grafana = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "grafana with authelia oidc";
    };

    dashboardsDir = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "directory containing grafana dashboard json files";
    };
  };

  config = lib.mkIf cfg.enable {
    # --- secrets ---

    clan.core.vars.generators.grafana = {
      files."oauth-client-secret-hash" = {
        owner = "authelia-main";
        group = "authelia-main";
      };
      files."oauth-client-secret" = {
        owner = "grafana";
        group = "grafana";
      };
      files."secret-key" = {
        owner = "grafana";
        group = "grafana";
      };

      runtimeInputs = with pkgs; [
        pwgen
        openssl
        authelia
      ];
      script = ''
        SECRET=$(pwgen -s 64 1)
        SECRET_KEY=$(openssl rand -hex 32)
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
        require_pkce = true;
        pkce_challenge_method = "S256";
        redirect_uris = [
          "https://${serviceDomain}/login/generic_oauth"
        ];
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
        token_endpoint_auth_method = "client_secret_basic";
        id_token_signed_response_alg = "RS256";
        claims_policy = "grafana_groups";
      }
    ];

    # --- service ---

    # provision dashboards via /etc
    environment.etc = lib.mkIf (cfg.dashboardsDir != null) (
      builtins.listToAttrs (
        map (file: {
          name = "grafana-dashboards/${file}";
          value.source = "${cfg.dashboardsDir}/${file}";
        }) (builtins.attrNames (builtins.readDir cfg.dashboardsDir))
      )
    );

    services.grafana = {
      enable = true;
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
            disableDeletion = true;
            editable = true;
            options.path = "/etc/grafana-dashboards";
          }
        ];
      };

      settings = {
        server = {
          http_addr = bindAddress;
          http_port = port;
          domain = serviceDomain;
          root_url = "https://${serviceDomain}";
          enable_gzip = true;
        };

        analytics = {
          reporting_enabled = false;
          check_for_updates = false;
        };

        security = {
          admin_user = "admin";
          cookie_secure = true;
          admin_password = "$__file{${config.sops.secrets."admin-password".path}}";
          secret_key = "$__file{${config.clan.core.vars.generators.grafana.files."secret-key".path}}";
        };

        users = {
          allow_sign_up = false;
          auto_assign_org = true;
        };

        #auth = {
        #  disable_login_form = true;
        #  oauth_auto_login = true;
        #};

        "auth.generic_oauth" = {
          enabled = true;
          name = "Authelia";
          use_refresh_token = true;
          icon = "signin";
          #allow_sign_up = true;
          #auto_login = true;
          client_id = "grafana";
          client_secret = "$__file{${
            config.clan.core.vars.generators.grafana.files."oauth-client-secret".path
          }}";
          scopes = "openid profile email groups offline_access";
          auth_url = "https://auth.${publicDomain}/api/oidc/authorization";
          token_url = "https://auth.${publicDomain}/api/oidc/token";
          api_url = "https://auth.${publicDomain}/api/oidc/userinfo";
          signout_redirect_url = "https://auth.${publicDomain}/logout";
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

    # --- homepage ---

    nixfiles.homepage.entries = lib.mkIf config.services.homepage-dashboard.enable [
      {
        name = "Grafana";
        category = "Monitoring";
        icon = "grafana.svg";
        href = "https://${serviceDomain}";
        siteMonitor = internalUrl;
      }
    ];

    # --- gatus ---

    nixfiles.gatus.endpoints = lib.mkIf config.nixfiles.gatus.enable [
      {
        name = "Grafana";
        url = "https://${serviceDomain}";
        group = "Monitoring";
      }
    ];

    # --- caddy ---

    nixfiles.caddy.vhosts.grafana = {
      inherit port;
    };
  };
}
