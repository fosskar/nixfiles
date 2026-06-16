{
  flake.modules.nixos.vaultwarden =
    {
      flake-self,
      config,
      lib,
      pkgs,
      nflib,
      ...
    }:
    let
      serviceName = "vault";
      localHost = "${serviceName}.${flake-self.domains.local}";
      listenAddress = "127.0.0.1";
      listenPort = 8222;
      listenUrl = "http://${listenAddress}:${toString listenPort}";
    in
    {
      # dashboard tile + health check via the default options (collected
      # clan-wide by the homepage/gatus collectors)
      services.homepage-dashboard.serviceGroups."security" = [
        {
          "Vaultwarden" = {
            href = "https://${localHost}";
            icon = "vaultwarden.svg";
            siteMonitor = listenUrl;
          };
        }
      ];

      services.gatus.settings.endpoints = [
        (nflib.gatusEndpoint {
          name = "Vaultwarden";
          url = "https://${localHost}";
          group = "security";
        })
      ];

      services.caddy.virtualHosts.${localHost}.extraConfig = ''
        header {
          X-Content-Type-Options "nosniff"
          X-Frame-Options "SAMEORIGIN"
          X-Robots-Tag "noindex, nofollow, nosnippet, noarchive"
          X-Download-Options "noopen"
          X-Permitted-Cross-Domain-Policies "none"
        }
        reverse_proxy ${listenUrl}
      '';

      services.authelia.instances.main.settings.identity_providers.oidc.clients = [
        {
          client_id = "vaultwarden";
          client_name = "Vaultwarden";
          client_secret = "{{ secret \"${
            config.clan.core.vars.generators.vaultwarden.files."oauth-client-secret-hash".path
          }\" }}";
          public = false;
          consent_mode = "implicit";
          authorization_policy = "users";
          require_pkce = true;
          pkce_challenge_method = "S256";
          redirect_uris = [ "https://${localHost}/identity/connect/oidc-signin" ];
          scopes = [
            "openid"
            "profile"
            "email"
          ];
          response_types = [ "code" ];
          grant_types = [ "authorization_code" ];
          token_endpoint_auth_method = "client_secret_basic";
        }
      ];

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

        runtimeInputs = [
          pkgs.pwgen
          pkgs.authelia
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
          USE_SYSLOG = true;
          LOG_LEVEL = "info";
          ROCKET_LOG = "info";

          USE_SENDMAIL = true;
          SENDMAIL_COMMAND = "/run/wrappers/bin/sendmail";
          SMTP_FROM = "noreply@${flake-self.domains.local}";
          SMTP_FROM_NAME = "Vaultwarden";

          SSO_PKCE = true;
          SSO_CLIENT_ID = "vaultwarden";
          SSO_ENABLED = true;
          SSO_ONLY = false;
          SSO_AUTHORITY = "https://auth.${flake-self.domains.public}";

          # decouple vaultwarden session from sso token lifetime
          SSO_AUTH_ONLY_NOT_SESSION = true;
        };
      };

      clan.core.postgresql.enable = lib.mkForce true;
      clan.core.postgresql.databases.vaultwarden = {
        create.enable = false;
        restore.stopOnRestore = [ "vaultwarden.service" ];
      };
    };
}
