{
  flake.modules.nixos.miniflux =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      acmeDomain = "nx3.eu";
      publicDomain = "fosskar.eu";
      serviceDomain = "feed.${acmeDomain}";
      bindAddress = "127.0.0.1";
      port = 8787;
      internalUrl = "http://${bindAddress}:${toString port}";
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
          redirect_uris = [ "https://${serviceDomain}/oauth2/oidc/callback" ];
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
          LISTEN_ADDR = "${bindAddress}:${toString port}";
          BASE_URL = "https://${serviceDomain}";
          CLEANUP_FREQUENCY_HOURS = "48";

          OAUTH2_PROVIDER = "oidc";
          OAUTH2_CLIENT_ID = "miniflux";
          OAUTH2_REDIRECT_URL = "https://${serviceDomain}/oauth2/oidc/callback";
          OAUTH2_OIDC_DISCOVERY_ENDPOINT = "https://auth.${publicDomain}";
          OAUTH2_USER_CREATION = "1";
        };
      };

      services.homepage-dashboard.serviceGroups."Media" =
        lib.mkIf config.services.homepage-dashboard.enable
          [
            {
              "Miniflux" = {
                href = "https://${serviceDomain}";
                icon = "miniflux.svg";
                siteMonitor = internalUrl;
              };
            }
          ];

      services.gatus.settings.endpoints = lib.mkIf config.services.gatus.enable [
        {
          name = "Miniflux";
          url = "https://${serviceDomain}";
          group = "Media";
          enabled = true;
          interval = "5m";
          conditions = [ "[STATUS] == 200" ];
          alerts = [ { type = "ntfy"; } ];
        }
      ];

      services.caddy.virtualHosts."feed.nx3.eu".extraConfig = ''
        reverse_proxy 127.0.0.1:${toString port}
      '';

      clan.core.postgresql.enable = true;
      clan.core.postgresql.databases.miniflux = {
        create.enable = false;
        restore.stopOnRestore = [ "miniflux.service" ];
      };
    };
}
