{
  flake.modules.nixos.papra =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      serviceName = "papra";
      localHost = "${serviceName}.${config.domains.local}";
      listenAddress = "127.0.0.1";
      listenPort = 1221;
      listenUrl = "http://${listenAddress}:${toString listenPort}";
      oidcIssuerUrl = "https://auth.${config.domains.public}";
    in
    {
      clan.core.vars.generators.papra = {
        files = {
          "oauth-client-secret-hash" = {
            owner = "authelia-main";
            group = "authelia-main";
          };
          "envfile" = {
            owner = config.services.papra.user;
            group = config.services.papra.group;
          };
        };

        runtimeInputs = [
          pkgs.pwgen
          pkgs.authelia
        ];
        script = ''
          AUTH_SECRET=$(pwgen -s 64 1)
          OAUTH_SECRET=$(pwgen -s 64 1)
          authelia crypto hash generate pbkdf2 --password "$OAUTH_SECRET" | tail -1 | cut -d' ' -f2 > "$out/oauth-client-secret-hash"

          {
            echo "AUTH_SECRET=$AUTH_SECRET"
            echo 'AUTH_PROVIDERS_CUSTOMS=[{"providerId":"authelia","providerName":"Authelia","clientId":"papra","clientSecret":"'$OAUTH_SECRET'","type":"oidc","discoveryUrl":"${oidcIssuerUrl}/.well-known/openid-configuration","scopes":["openid","profile","email"]}]'
          } > "$out/envfile"
        '';
      };

      services.authelia.instances.main.settings.identity_providers.oidc.clients = [
        {
          client_id = "papra";
          client_name = "Papra";
          client_secret = "{{ secret \"${
            config.clan.core.vars.generators.papra.files."oauth-client-secret-hash".path
          }\" }}";
          public = false;
          consent_mode = "implicit";
          authorization_policy = "users";
          redirect_uris = [ "https://${localHost}/api/auth/oauth2/callback/authelia" ];
          scopes = [
            "openid"
            "profile"
            "email"
          ];
          response_types = [ "code" ];
          grant_types = [ "authorization_code" ];
          token_endpoint_auth_method = "client_secret_post";
        }
      ];

      services.papra = {
        enable = true;
        environment = {
          APP_BASE_URL = "https://${localHost}";
          PORT = listenPort;
          SERVER_HOSTNAME = listenAddress;
          DATABASE_URL = "file:/var/lib/papra/db.sqlite";
          DOCUMENT_STORAGE_FILESYSTEM_ROOT = "/var/lib/papra/documents";
          DOCUMENTS_OCR_LANGUAGES = "eng,deu";
        };
        environmentFile = config.clan.core.vars.generators.papra.files."envfile".path;
      };

      services.caddy.virtualHosts.${localHost}.extraConfig = ''
        reverse_proxy ${listenUrl}
      '';

      services.homepage-dashboard.serviceGroups."Files" =
        lib.mkIf config.services.homepage-dashboard.enable
          [
            {
              "Papra" = {
                href = "https://${localHost}";
                icon = "papra.svg";
                siteMonitor = listenUrl;
              };
            }
          ];

      services.gatus.settings.endpoints = lib.mkIf config.services.gatus.enable [
        {
          name = "Papra";
          url = "https://${localHost}";
          group = "Files";
          enabled = true;
          interval = "5m";
          conditions = [ "[STATUS] == 200" ];
          alerts = [ { type = "email"; } ];
        }
      ];
    };
}
