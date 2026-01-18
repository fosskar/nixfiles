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
in
{
  options.nixfiles.paperless = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "paperless-ngx document management";
    };
  };

  config = lib.mkIf cfg.enable {
    # generate paperless secrets
    clan.core.vars.generators.paperless = {
      files = {
        "admin-password" = {
          owner = "paperless";
          group = "paperless";
        };
        "oauth-client-secret-hash" = { };
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
        authelia crypto hash generate pbkdf2 --password "$SECRET" | tail -1 > "$out/oauth-client-secret-hash"
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

    # register oidc client with authelia
    # clan vars get hm-nixbox paperless/oauth-client-secret-hash
    services.authelia.instances.main.settings.identity_providers.oidc.clients = [
      {
        client_id = "paperless";
        client_name = "Paperless";
        client_secret = "$pbkdf2-sha512$310000$g4iE28Iw.uP2OC5Mq3uxqQ$XCcsIvXUEJd2G/CqcW.eyVSOen5Lm69E2rhLMIT4O7PH/rLnDeCextqKCHAd.8nv48PpWiv3zoyO15ZQambmXw";
        public = false;
        authorization_policy = "one_factor";
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

    # persist dataDir (on SSD, avoids waking HDDs)
    nixfiles.persistence.directories = [ config.services.paperless.dataDir ];

    # nginx reverse proxy
    nixfiles.nginx.vhosts.docs.port = config.services.paperless.port;

    services.paperless = {
      enable = true;
      address = "127.0.0.1";
      port = 28981;
      domain = serviceDomain;

      # storage locations (dataDir defaults to /var/lib/paperless - on SSD)
      mediaDir = "/tank/apps/paperless/media";
      consumptionDir = "/tank/apps/paperless/consume";

      # local postgresql
      database.createLocally = true;

      passwordFile = config.clan.core.vars.generators.paperless.files."admin-password".path;

      # oauth env with PAPERLESS_SOCIALACCOUNT_PROVIDERS
      environmentFile = config.clan.core.vars.generators.paperless.files."oauth.env".path;

      settings = {
        PAPERLESS_ADMIN_USER = "admin";
        PAPERLESS_OCR_LANGUAGE = "deu+eng";
        PAPERLESS_TIME_ZONE = "Europe/Berlin";
        PAPERLESS_TRUSTED_PROXIES = "138.201.155.21,127.0.0.1";

        PAPERLESS_CONSUMER_RECURSIVE = true;
        PAPERLESS_CONSUMER_SUBDIRS_AS_TAGS = true;

        PAPERLESS_CONSUMER_IGNORE_PATTERN = [
          ".DS_STORE/*"
          "desktop.ini"
        ];
        PAPERLESS_OCR_USER_ARGS = {
          optimize = 1;
          pdfa_image_compression = "lossless";
        };

        # oidc via authelia
        PAPERLESS_APPS = "allauth.socialaccount.providers.openid_connect";
        #PAPERLESS_SOCIALACCOUNT_EMAIL_AUTHENTICATION = true;
        PAPERLESS_SOCIALACCOUNT_EMAIL_AUTHENTICATION_AUTO_CONNECT = true;

        PAPERLESS_DISABLE_REGULAR_LOGIN = true;
        PAPERLESS_REDIRECT_LOGIN_TO_SSO = true;
      };
    };
  };
}
