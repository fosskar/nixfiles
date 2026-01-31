{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.nixfiles.monitoring.grafana;
  acmeDomain = config.nixfiles.acme.domain;
  inherit (config.nixfiles.authelia) publicDomain;
  serviceDomain = "grafana.${acmeDomain}";
in
{
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
    # provision dashboards via /etc
    environment.etc = lib.mkIf (cfg.dashboardsDir != null) (
      builtins.listToAttrs (
        map (file: {
          name = "grafana-dashboards/${file}";
          value.source = "${cfg.dashboardsDir}/${file}";
        }) (builtins.attrNames (builtins.readDir cfg.dashboardsDir))
      )
    );

    # generate grafana oauth secret
    clan.core.vars.generators.grafana = {
      files."oauth-client-secret-hash" = { };
      files."oauth-client-secret" = {
        owner = "grafana";
        group = "grafana";
      };

      runtimeInputs = with pkgs; [
        pwgen
        authelia
      ];
      script = ''
        SECRET=$(pwgen -s 64 1)
        authelia crypto hash generate pbkdf2 --password "$SECRET" | tail -1 > "$out/oauth-client-secret-hash"
        echo -n "$SECRET" > "$out/oauth-client-secret"
      '';
    };

    # register oidc client with authelia
    services.authelia.instances.main.settings.identity_providers.oidc.clients = [
      {
        client_id = "grafana";
        client_name = "Grafana";
        client_secret = "$pbkdf2-sha512$310000$YErtbDH5FQp5GSc8Pt/Lhg$1pwR1Cj4FmJIuZb6nvoZfx8MfvXXzKs5XQ52sU1TDhCZlYVPVlatf7vB0AY5mSqyWgAo3kJUJ6T1o2EBntyCfw";
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
        ];
        response_types = [ "code" ];
        grant_types = [ "authorization_code" ];
        token_endpoint_auth_method = "client_secret_basic";
      }
    ];

    # nginx reverse proxy
    nixfiles.nginx.vhosts.grafana.port = config.services.grafana.settings.server.http_port;

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
          http_addr = "127.0.0.1";
          http_port = 3100;
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
          icon = "signin";
          #allow_sign_up = true;
          #auto_login = true;
          client_id = "grafana";
          client_secret = "$__file{${
            config.clan.core.vars.generators.grafana.files."oauth-client-secret".path
          }}";
          scopes = "openid profile email groups";
          auth_url = "https://auth.${publicDomain}/api/oidc/authorization";
          token_url = "https://auth.${publicDomain}/api/oidc/token";
          api_url = "https://auth.${publicDomain}/api/oidc/userinfo";
          signout_redirect_url = "https://auth.${publicDomain}/logout";
          use_pkce = true;
          login_attribute_path = "preferred_username";
          name_attribute_path = "name";
          role_attribute_path = "contains(groups[*], 'lldap_admin') && 'GrafanaAdmin' || 'Editor'";
          allow_assign_grafana_admin = true;
        };
      };
    };
  };
}
