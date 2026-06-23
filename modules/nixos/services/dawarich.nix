{
  flake.modules.nixos.dawarich =
    {
      flake-self,
      config,
      pkgs,
      ...
    }:
    let
      serviceName = "dawarich";
      localHost = "${serviceName}.${flake-self.domains.local}";
      listenAddress = "127.0.0.1";
      listenPort = 17190;
      listenUrl = "http://${listenAddress}:${toString listenPort}";
    in
    {
      clan.core.vars.generators.dawarich = {
        files."secret-key-base" = { };
        files."oauth-client-secret-hash" = {
          owner = "authelia-main";
          group = "authelia-main";
        };
        files."oidc-env" = { };
        runtimeInputs = [
          pkgs.openssl
          pkgs.pwgen
          pkgs.authelia
        ];
        script = ''
          openssl rand -hex 64 | tr -d '\n' > "$out/secret-key-base"

          SECRET=$(pwgen -s 64 1)
          authelia crypto hash generate pbkdf2 --password "$SECRET" | tail -1 | cut -d' ' -f2 > "$out/oauth-client-secret-hash"
          echo "OIDC_CLIENT_SECRET=$SECRET" > "$out/oidc-env"
        '';
      };

      services.authelia.instances.main.settings.identity_providers.oidc.clients = [
        {
          client_id = "dawarich";
          client_name = "Dawarich";
          client_secret = "{{ secret \"${
            config.clan.core.vars.generators.dawarich.files."oauth-client-secret-hash".path
          }\" }}";
          public = false;
          consent_mode = "implicit";
          authorization_policy = "users";
          require_pkce = true;
          pkce_challenge_method = "S256";
          redirect_uris = [ "https://${localHost}/users/auth/openid_connect/callback" ];
          scopes = [
            "openid"
            "profile"
            "email"
          ];
          response_types = [ "code" ];
          grant_types = [ "authorization_code" ];
          access_token_signed_response_alg = "none";
          userinfo_signed_response_alg = "none";
          token_endpoint_auth_method = "client_secret_basic";
        }
      ];

      services.dawarich = {
        enable = true;
        localDomain = localHost;
        webPort = listenPort;
        configureNginx = false;

        secretKeyBaseFile = config.clan.core.vars.generators.dawarich.files."secret-key-base".path;

        database.createLocally = true;
        redis.createLocally = true;

        smtp = {
          host = "smtp.mailbox.org";
          port = 587;
          fromAddress = "noreply@nx3.eu";
        };

        # SMTP_USERNAME + SMTP_PASSWORD from shared smtp generator;
        # OIDC_CLIENT_SECRET from dawarich generator
        extraEnvFiles = [
          config.clan.core.vars.generators.smtp.files."smtp-env".path
          config.clan.core.vars.generators.dawarich.files."oidc-env".path
        ];

        environment = {
          # server profile sets UTC; dawarich users are local time
          TIME_ZONE = "Europe/Berlin";

          OIDC_CLIENT_ID = "dawarich";
          OIDC_ISSUER = "https://auth.${flake-self.domains.public}";
          OIDC_REDIRECT_URI = "https://${localHost}/users/auth/openid_connect/callback";
          OIDC_PKCE_ENABLED = "true";
          OIDC_PROVIDER_NAME = "Authelia";

          # OIDC-only: dawarich ignores OIDC groups, so no role mapping.
          # disable local email/password login + registration; the seeded
          # demo@dawarich.app admin is thereby locked out. promote a real
          # OIDC user to admin via dawarich-console (see module notes).
          OIDC_AUTO_REGISTER = "true";
          ALLOW_EMAIL_PASSWORD_LOGIN = "false";
          ALLOW_EMAIL_PASSWORD_REGISTRATION = "false";
        };
      };

      services.homepage-dashboard.services = [
        {
          "media" = [
            {
              "Dawarich" = {
                href = "https://${localHost}";
                icon = "dawarich.png";
                siteMonitor = listenUrl;
              };
            }
          ];
        }
      ];

      services.gatus.settings.endpoints = [
        {
          name = "Dawarich";
          url = "https://${localHost}";
          group = "Media";
          enabled = true;
          alerts = [ { type = "email"; } ];
          interval = "5m";
          conditions = [ "[STATUS] == 200" ];
        }
      ];

      services.caddy.virtualHosts.${localHost}.extraConfig = ''
        root * ${config.services.dawarich.package}/public
        @notFound not file
        reverse_proxy @notFound ${listenUrl}
        file_server
      '';

      clan.core.postgresql.enable = true;
      clan.core.postgresql.databases.dawarich = {
        create.enable = false;
        restore.stopOnRestore = [
          "dawarich-web.service"
          "dawarich-sidekiq-all.service"
          "redis-dawarich.service"
        ];
      };
    };
}
