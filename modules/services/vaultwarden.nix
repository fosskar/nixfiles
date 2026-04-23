{
  flake.modules.nixos.vaultwarden =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      acmeDomain = "nx3.eu";
      publicDomain = "fosskar.eu";
      serviceDomain = "vault.${acmeDomain}";
      bindAddress = "127.0.0.1";
      port = 8222;
      internalUrl = "http://${bindAddress}:${toString port}";
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
          redirect_uris = [ "https://${serviceDomain}/identity/connect/oidc-signin" ];
          scopes = [
            "openid"
            "offline_access"
            "profile"
            "email"
          ];
          response_types = [ "code" ];
          grant_types = [
            "authorization_code"
            "refresh_token"
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
          DOMAIN = "https://${serviceDomain}";
          ROCKET_ADDRESS = bindAddress;
          ROCKET_PORT = port;

          SIGNUPS_ALLOWED = false;
          INVITATIONS_ALLOWED = true;
          SHOW_PASSWORD_HINT = false;

          SSO_PKCE = true;
          SSO_CLIENT_ID = "vaultwarden";
          SSO_ENABLED = true;
          SSO_ONLY = false;
          SSO_AUTHORITY = "https://auth.${publicDomain}";

          # decouple vaultwarden session from sso token lifetime
          SSO_AUTH_ONLY_NOT_SESSION = true;
        };
      };

      services.homepage-dashboard.services = lib.mkIf config.services.homepage-dashboard.enable [
        {
          "Security" = [
            {
              "Vaultwarden" = {
                href = "https://${serviceDomain}";
                icon = "vaultwarden.svg";
                siteMonitor = internalUrl;
              };
            }
          ];
        }
      ];

      services.gatus.settings.endpoints = lib.mkIf config.services.gatus.enable [
        {
          name = "Vaultwarden";
          url = "https://${serviceDomain}";
          group = "Security";
          enabled = true;
          interval = "5m";
          conditions = [ "[STATUS] == 200" ];
          alerts = [ { type = "ntfy"; } ];
        }
      ];

      services.caddy.virtualHosts."vault.nx3.eu".extraConfig = ''
        reverse_proxy 127.0.0.1:${toString port}
      '';

      clan.core.postgresql.enable = lib.mkForce true;
      clan.core.postgresql.databases.vaultwarden = {
        create.enable = false;
        restore.stopOnRestore = [ "vaultwarden.service" ];
      };
    };
}
