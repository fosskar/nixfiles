{
  flake.modules.nixos.miniflux =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      serviceName = "feed";
      localHost = "${serviceName}.${config.domains.local}";
      listenAddress = "127.0.0.1";
      listenPort = 8787;
      listenUrl = "http://${listenAddress}:${toString listenPort}";

    in
    {
      clan.core.vars.generators.miniflux = {
        files = {
          "oauth-client-secret-hash" = {
            owner = "authelia-main";
            group = "authelia-main";
          };
          "oauth-client-secret" = { };
          "credentials" = { };
        };

        runtimeInputs = with pkgs; [
          pwgen
          authelia
        ];
        script = ''
          # oauth secret
          SECRET=$(pwgen -s 64 1)
          authelia crypto hash generate pbkdf2 --password "$SECRET" | tail -1 | cut -d' ' -f2 > "$out/oauth-client-secret-hash"
          echo -n "$SECRET" > "$out/oauth-client-secret"

          # admin credentials
          ADMIN_PW=$(pwgen -s 48 1)
          {
            echo "ADMIN_USERNAME=admin"
            echo "ADMIN_PASSWORD=$ADMIN_PW"
            echo "OAUTH2_CLIENT_SECRET=$SECRET"
          } > "$out/credentials"
        '';
      };

      services.authelia.instances.main.settings.identity_providers.oidc.clients = [
        {
          client_id = "miniflux";
          client_name = "Miniflux";
          client_secret = "{{ secret \"${
            config.clan.core.vars.generators.miniflux.files."oauth-client-secret-hash".path
          }\" }}";
          public = false;
          consent_mode = "implicit";
          authorization_policy = "users";
          redirect_uris = [ "https://${localHost}/oauth2/oidc/callback" ];
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

      services.miniflux = {
        enable = true;
        createDatabaseLocally = true;

        adminCredentialsFile = config.clan.core.vars.generators.miniflux.files."credentials".path;

        config = {
          LISTEN_ADDR = "${listenAddress}:${toString listenPort}";
          BASE_URL = "https://${localHost}";
          CLEANUP_FREQUENCY_HOURS = "48";

          OAUTH2_PROVIDER = "oidc";
          OAUTH2_CLIENT_ID = "miniflux";
          OAUTH2_REDIRECT_URL = "https://${localHost}/oauth2/oidc/callback";
          OAUTH2_OIDC_DISCOVERY_ENDPOINT = "https://auth.${config.domains.public}";
          OAUTH2_USER_CREATION = "1";
        };
      };

      services.homepage-dashboard.serviceGroups."Media" =
        lib.mkIf config.services.homepage-dashboard.enable
          [
            {
              "Miniflux" = {
                href = "https://${localHost}";
                icon = "miniflux.svg";
                siteMonitor = listenUrl;
              };
            }
          ];

      services.gatus.settings.endpoints = lib.mkIf config.services.gatus.enable [
        {
          name = "Miniflux";
          url = "https://${localHost}";
          group = "Media";
          enabled = true;
          interval = "5m";
          conditions = [ "[STATUS] == 200" ];
          alerts = [ { type = "ntfy"; } ];
        }
      ];

      services.caddy.virtualHosts.${localHost}.extraConfig = ''
        reverse_proxy ${listenUrl}
      '';

      clan.core.postgresql.enable = true;
      clan.core.postgresql.databases.miniflux = {
        create.enable = false;
        restore.stopOnRestore = [ "miniflux.service" ];
      };
    };
}
