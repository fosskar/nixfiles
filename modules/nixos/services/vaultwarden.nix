{
  flake.modules.nixos.vaultwarden =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      serviceName = "vault";
      localHost = "${serviceName}.${config.domains.local}";
      listenAddress = "127.0.0.1";
      listenPort = 8222;
      listenUrl = "http://${listenAddress}:${toString listenPort}";
    in
    {
      clan.core.vars.generators.vaultwarden = {
        files = {
          "oauth-client-secret-hash" = {
            owner = "authelia-main";
            group = "authelia-main";
          };
          "oauth-client-secret" = { };
          "admin-token" = { };
          "sso.env" = { };
        };

        runtimeInputs = with pkgs; [
          pwgen
          authelia
        ];
        script = ''
          SECRET=$(pwgen -s 64 1)
          authelia crypto hash generate pbkdf2 --password "$SECRET" | tail -1 | cut -d' ' -f2 > "$out/oauth-client-secret-hash"
          echo -n "$SECRET" > "$out/oauth-client-secret"

          ADMIN=$(pwgen -s 48 1)
          echo -n "$ADMIN" > "$out/admin-token"

          {
            echo "SSO_CLIENT_SECRET=$SECRET"
            echo "ADMIN_TOKEN=$ADMIN"
          } > "$out/sso.env"
        '';
      };

      services.authelia.instances.main.settings.identity_providers.oidc.clients = [
        {
          client_id = "vaultwarden";
          client_name = "Vaultwarden";
          client_secret = "{{ secret \"${
            config.clan.core.vars.generators.vaultwarden.files."oauth-client-secret-hash".path
          }\" }}";
          public = false;
          consent_mode = "implicit";
          require_pkce = true;
          pkce_challenge_method = "S256";
          redirect_uris = [ "https://${localHost}/identity/connect/oidc-signin" ];
          scopes = [
            "openid"
            "profile"
            "email"
          ];
          response_types = [ "code" ];
          grant_types = [
            "authorization_code"
          ];
          token_endpoint_auth_method = "client_secret_basic";
        }
      ];

      services.vaultwarden = {
        enable = true;
        dbBackend = "postgresql";
        configurePostgres = true;
        environmentFile = config.clan.core.vars.generators.vaultwarden.files."sso.env".path;

        config = {
          DOMAIN = "https://${localHost}";
          ROCKET_ADDRESS = listenAddress;
          ROCKET_PORT = listenPort;

          SIGNUPS_ALLOWED = false;
          INVITATIONS_ALLOWED = true;
          SHOW_PASSWORD_HINT = false;

          SSO_PKCE = true;
          SSO_CLIENT_ID = "vaultwarden";
          SSO_ENABLED = true;
          SSO_ONLY = false;
          SSO_AUTHORITY = "https://auth.${config.domains.public}";

          # decouple vaultwarden session from sso token lifetime
          SSO_AUTH_ONLY_NOT_SESSION = true;
        };
      };

      services.homepage-dashboard.serviceGroups."Security" =
        lib.mkIf config.services.homepage-dashboard.enable
          [
            {
              "Vaultwarden" = {
                href = "https://${localHost}";
                icon = "vaultwarden.svg";
                siteMonitor = listenUrl;
              };
            }
          ];

      services.gatus.settings.endpoints = lib.mkIf config.services.gatus.enable [
        {
          name = "Vaultwarden";
          url = "https://${localHost}";
          group = "Security";
          enabled = true;
          interval = "5m";
          conditions = [ "[STATUS] == 200" ];
          alerts = [ { type = "ntfy"; } ];
        }
      ];

      services.caddy.virtualHosts.${localHost}.extraConfig = ''
        reverse_proxy ${listenUrl}
      '';

      clan.core.postgresql.enable = lib.mkForce true;
      clan.core.postgresql.databases.vaultwarden = {
        create.enable = false;
        restore.stopOnRestore = [ "vaultwarden.service" ];
      };
    };
}
