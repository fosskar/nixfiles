{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.nixfiles.miniflux;
  acmeDomain = config.nixfiles.caddy.domain;
  inherit (config.nixfiles.authelia) publicDomain;
  serviceDomain = "feed.${acmeDomain}";
  bindAddress = "127.0.0.1";
  port = 8787;
  internalUrl = "http://${bindAddress}:${toString port}";
in
{
  # --- options ---

  options.nixfiles.miniflux = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "miniflux rss feed reader";
    };
  };

  config = lib.mkIf cfg.enable {
    # --- secrets ---

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

    # --- oidc ---

    services.authelia.instances.main.settings.identity_providers.oidc.clients = [
      {
        client_id = "miniflux";
        client_name = "Miniflux";
        client_secret = "{{ secret \"${
          config.clan.core.vars.generators.miniflux.files."oauth-client-secret-hash".path
        }\" }}";
        public = false;
        consent_mode = "implicit";
        redirect_uris = [
          "https://${serviceDomain}/oauth2/oidc/callback"
        ];
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

    # --- service ---

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

    # --- homepage ---

    nixfiles.homepage.entries = lib.mkIf config.services.homepage-dashboard.enable [
      {
        name = "Miniflux";
        category = "Media";
        icon = "miniflux.svg";
        href = "https://${serviceDomain}";
        siteMonitor = internalUrl;
      }
    ];

    # --- gatus ---

    nixfiles.gatus.endpoints = lib.mkIf config.nixfiles.gatus.enable [
      {
        name = "Miniflux";
        url = "https://${serviceDomain}";
        group = "Media";
      }
    ];

    # --- caddy ---

    nixfiles.caddy.vhosts.feed = {
      inherit port;
    };

    # --- backup ---

    clan.core.postgresql.enable = true;
    clan.core.postgresql.databases.miniflux = {
      create.enable = false; # miniflux module creates it
      restore.stopOnRestore = [ "miniflux.service" ];
    };
  };
}
