{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.nixfiles.paperless;
  acmeDomain = config.nixfiles.acme.domain;
  inherit (config.nixfiles.authelia) publicDomain;
  serviceDomain = "docs.${acmeDomain}";
  bindAddress = "127.0.0.1";
  port = 28981;
  internalUrl = "http://${bindAddress}:${toString port}";
in
{
  imports = [ ./samba.nix ];

  # --- options ---

  options.nixfiles.paperless = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "paperless-ngx document management";
    };

  };

  config = lib.mkIf cfg.enable {
    # --- secrets ---

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
        # oauth secret
        SECRET=$(pwgen -s 64 1)
        authelia crypto hash generate pbkdf2 --password "$SECRET" | tail -1 | cut -d' ' -f2 > "$out/oauth-client-secret-hash"
        echo -n "$SECRET" > "$out/oauth-client-secret"

        # admin password
        pwgen -s 32 1 | tr -d '\n' > "$out/admin-password"

        # oauth env file with socialaccount providers json
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
                  "server_url": "https://auth.${publicDomain}",
                  "token_auth_method": "client_secret_basic"
                }
              }]
            }
          }')
        echo "PAPERLESS_SOCIALACCOUNT_PROVIDERS=$JSON" > "$out/oauth.env"
      '';
    };

    # --- oidc ---

    services.authelia.instances.main.settings.identity_providers.oidc.clients = [
      {
        client_id = "paperless";
        client_name = "Paperless";
        client_secret = "{{ secret \"${
          config.clan.core.vars.generators.paperless.files."oauth-client-secret-hash".path
        }\" }}";
        public = false;
        consent_mode = "implicit";
        require_pkce = true;
        pkce_challenge_method = "S256";
        redirect_uris = [
          "https://${serviceDomain}/accounts/oidc/authelia/login/callback/"
        ];
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

    # --- service ---

    # paperless needs to traverse nextcloud data dir to reach groupfolder consume dir
    users.users.paperless.extraGroups = [ "opencloud" ];

    services.paperless = {
      enable = true;
      address = bindAddress;
      inherit port;
      domain = serviceDomain;

      # storage locations (dataDir defaults to /var/lib/paperless - on SSD)
      mediaDir = "/tank/apps/paperless/media";
      #consumptionDir = "/tank/apps/nextcloud/data/__groupfolders/1/files/documents/consume";
      consumptionDir = "/tank/apps/opencloud/data/projects/f9beb848-8a0b-4be6-ad43-fdce26636a4b";
      #consumptionDir = "/tank/apps/paperless/consume";
      consumptionDirIsPublic = true;

      # local postgresql
      database.createLocally = true;

      passwordFile = config.clan.core.vars.generators.paperless.files."admin-password".path;

      # oauth env with PAPERLESS_SOCIALACCOUNT_PROVIDERS
      environmentFile = config.clan.core.vars.generators.paperless.files."oauth.env".path;

      settings = {
        PAPERLESS_ADMIN_USER = "admin";
        PAPERLESS_OCR_LANGUAGE = "deu+eng";
        PAPERLESS_LOGOUT_REDIRECT_URL = "https://auth.${publicDomain}/logout";
        PAPERLESS_TIME_ZONE = "Europe/Berlin";
        PAPERLESS_DATE_ORDER = "DMY";
        PAPERLESS_TRUSTED_PROXIES = "138.201.155.21,127.0.0.1";

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

        # oidc via authelia
        PAPERLESS_APPS = "allauth.socialaccount.providers.openid_connect";
        #PAPERLESS_SOCIALACCOUNT_EMAIL_AUTHENTICATION = true;
        PAPERLESS_SOCIALACCOUNT_EMAIL_AUTHENTICATION_AUTO_CONNECT = true;

        PAPERLESS_DISABLE_REGULAR_LOGIN = false;
        PAPERLESS_REDIRECT_LOGIN_TO_SSO = false;
      };
    };

    # --- homepage ---

    nixfiles.homepage.entries = lib.mkIf config.services.homepage-dashboard.enable [
      {
        name = "Paperless";
        category = "Documents";
        icon = "paperless.png";
        href = "https://${serviceDomain}";
        siteMonitor = internalUrl;
      }
    ];

    # --- gatus ---

    nixfiles.gatus.endpoints = lib.mkIf config.nixfiles.gatus.enable [
      {
        name = "Paperless";
        url = "https://${serviceDomain}";
        group = "Documents";
      }
    ];

    # --- nginx ---

    nixfiles.nginx.vhosts.docs = {
      inherit port;
    };

    # --- backup ---

    clan.core.postgresql.enable = true;
    clan.core.postgresql.databases.paperless = {
      create.enable = false; # paperless module creates it
      restore.stopOnRestore = [
        "paperless-consumer.service"
        "paperless-scheduler.service"
        "paperless-task-queue.service"
        "paperless-web.service"
        "redis-paperless.service"
      ];
    };

    # --- persistence ---

    nixfiles.persistence.directories = [
      {
        directory = config.services.paperless.dataDir;
        user = "paperless";
        group = "paperless";
      }
    ];
  };
}
