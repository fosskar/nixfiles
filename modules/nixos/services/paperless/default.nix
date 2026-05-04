{
  flake.modules.nixos.paperless =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      serviceName = "docs";
      localHost = "${serviceName}.${config.domains.local}";
      listenAddress = "127.0.0.1";
      listenPort = 28981;
      listenUrl = "http://${listenAddress}:${toString listenPort}";

    in
    {
      clan.core.vars.generators.paperless = {
        files = {
          "admin-password" = {
            owner = "paperless";
            group = "paperless";
          };
          "oauth-client-secret-hash" = {
            owner = "authelia-main";
            group = "authelia-main";
          };
          "oauth-client-secret" = {
            owner = "paperless";
            group = "paperless";
          };
          "oauth.env" = {
            owner = "paperless";
            group = "paperless";
          };
        };

        runtimeInputs = with pkgs; [
          pwgen
          authelia
          jq
        ];
        script = ''
          SECRET=$(pwgen -s 64 1)
          authelia crypto hash generate pbkdf2 --password "$SECRET" | tail -1 | cut -d' ' -f2 > "$out/oauth-client-secret-hash"
          echo -n "$SECRET" > "$out/oauth-client-secret"

          pwgen -s 32 1 | tr -d '\n' > "$out/admin-password"

          JSON=$(jq -c -n \
            --arg secret "$SECRET" \
            '{
              "openid_connect": {
                "SCOPE": ["openid", "profile", "email", "groups"],
                "OAUTH_PKCE_ENABLED": true,
                "APPS": [{
                  "provider_id": "authelia",
                  "name": "Authelia",
                  "client_id": "paperless",
                  "secret": $secret,
                  "settings": {
                    "server_url": "https://auth.${config.domains.public}",
                    "token_auth_method": "client_secret_basic"
                  }
                }]
              }
            }')
          echo "PAPERLESS_SOCIALACCOUNT_PROVIDERS=$JSON" > "$out/oauth.env"
        '';
      };

      services.authelia.instances.main.settings.identity_providers.oidc.clients = [
        {
          client_id = "paperless";
          client_name = "Paperless";
          client_secret = "{{ secret \"${
            config.clan.core.vars.generators.paperless.files."oauth-client-secret-hash".path
          }\" }}";
          public = false;
          consent_mode = "implicit";
          authorization_policy = "users";
          require_pkce = true;
          pkce_challenge_method = "S256";
          redirect_uris = [ "https://${localHost}/accounts/oidc/authelia/login/callback/" ];
          scopes = [
            "openid"
            "profile"
            "email"
            "groups"
          ];
          response_types = [ "code" ];
          grant_types = [ "authorization_code" ];
          access_token_signed_response_alg = "none";
          userinfo_signed_response_alg = "none";
          token_endpoint_auth_method = "client_secret_basic";
        }
      ];

      users.groups.shared.members = [
        "nextcloud"
        "paperless"
      ];

      users.users.paperless.extraGroups = [ "shared" ];

      systemd.tmpfiles.rules = [
        "Z /tank/shares/shared/documents/consume 2775 paperless shared -"
      ];

      services.paperless = {
        enable = true;
        address = listenAddress;
        port = listenPort;
        domain = localHost;

        mediaDir = "/tank/apps/paperless/media";
        consumptionDir = "/tank/shares/shared/documents/consume";
        consumptionDirIsPublic = true;

        database.createLocally = true;

        passwordFile = config.clan.core.vars.generators.paperless.files."admin-password".path;

        environmentFile = config.clan.core.vars.generators.paperless.files."oauth.env".path;

        settings = {
          PAPERLESS_ADMIN_USER = "admin";
          PAPERLESS_OCR_LANGUAGE = "deu+eng";
          PAPERLESS_LOGOUT_REDIRECT_URL = "https://auth.${config.domains.public}/logout";
          PAPERLESS_TIME_ZONE = "Europe/Berlin";
          PAPERLESS_DATE_ORDER = "DMY";
          PAPERLESS_TRUSTED_PROXIES = "138.201.155.21,127.0.0.1";
          PAPERLESS_ARCHIVE_FILE_GENERATION = "always";

          PAPERLESS_TASK_WORKERS = 2;
          PAPERLESS_WEBSERVER_WORKERS = 2;

          PAPERLESS_CONSUMER_RECURSIVE = true;
          PAPERLESS_CONSUMER_SUBDIRS_AS_TAGS = true;
          PAPERLESS_CONSUMER_DELETE_DUPLICATES = true;

          PAPERLESS_CONSUMER_IGNORE_PATTERN = [
            ".DS_STORE/*"
            "desktop.ini"
            ".space/**"
            ".oc-nodes/**"
            ".oc-tmp/**"
            ".Trash/**"
          ];
          PAPERLESS_OCR_USER_ARGS = {
            language = "deu+eng";
            rotate_pages = true;
          };

          PAPERLESS_APPS = "allauth.socialaccount.providers.openid_connect";
          PAPERLESS_SOCIALACCOUNT_EMAIL_AUTHENTICATION_AUTO_CONNECT = true;

          PAPERLESS_DISABLE_REGULAR_LOGIN = false;
          PAPERLESS_REDIRECT_LOGIN_TO_SSO = false;
        };
      };

      services.homepage-dashboard.serviceGroups."Files" =
        lib.mkIf config.services.homepage-dashboard.enable
          [
            {
              "Paperless" = {
                href = "https://${localHost}";
                icon = "paperless.png";
                siteMonitor = listenUrl;
              };
            }
          ];

      services.gatus.settings.endpoints = lib.mkIf config.services.gatus.enable [
        {
          name = "Paperless";
          url = "https://${localHost}";
          group = "Files";
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
      clan.core.postgresql.databases.paperless = {
        create.enable = false;
        restore.stopOnRestore = [
          "paperless-consumer.service"
          "paperless-scheduler.service"
          "paperless-task-queue.service"
          "paperless-web.service"
          "redis-paperless.service"
        ];
      };

      preservation.preserveAt."/persist".directories = [
        {
          directory = config.services.paperless.dataDir;
          user = "paperless";
          group = "paperless";
        }
      ];
    };
}
