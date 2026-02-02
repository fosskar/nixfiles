{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.nixfiles.vaultwarden;
  acmeDomain = config.nixfiles.acme.domain;
  inherit (config.nixfiles.authelia) publicDomain;
  serviceDomain = "vault.${acmeDomain}";
in
{
  options.nixfiles.vaultwarden = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "vaultwarden password manager";
    };
  };

  config = lib.mkIf cfg.enable {
    # generate vaultwarden secrets
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
        # oauth secret
        SECRET=$(pwgen -s 64 1)
        authelia crypto hash generate pbkdf2 --password "$SECRET" | tail -1 | cut -d' ' -f2 > "$out/oauth-client-secret-hash"
        echo -n "$SECRET" > "$out/oauth-client-secret"

        # admin token
        ADMIN=$(pwgen -s 48 1)
        echo -n "$ADMIN" > "$out/admin-token"

        # sso env file
        {
          echo "SSO_CLIENT_SECRET=$SECRET"
          echo "ADMIN_TOKEN=$ADMIN"
        } > "$out/sso.env"
      '';
    };

    # register oidc client with authelia
    # clan vars get hm-nixbox vaultwarden/oauth-client-secret-hash
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
        redirect_uris = [
          "https://${serviceDomain}/identity/connect/oidc-signin"
        ];
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

    # nginx reverse proxy
    nixfiles.nginx.vhosts.vault.port = config.services.vaultwarden.config.ROCKET_PORT;

    # postgresql backup/restore integration
    clan.core.postgresql.enable = true;
    clan.core.postgresql.databases.vaultwarden = {
      create.enable = false; # vaultwarden module creates it
      restore.stopOnRestore = [ "vaultwarden.service" ];
    };

    services.vaultwarden = {
      enable = true;
      dbBackend = "postgresql";
      configurePostgres = true;
      environmentFile = config.clan.core.vars.generators.vaultwarden.files."sso.env".path;

      config = {
        DOMAIN = "https://${serviceDomain}";
        ROCKET_ADDRESS = "127.0.0.1";
        ROCKET_PORT = 8222;

        SIGNUPS_ALLOWED = false;
        INVITATIONS_ALLOWED = true;
        SHOW_PASSWORD_HINT = false;

        SSO_PKCE = true;
        SSO_CLIENT_ID = "vaultwarden";
        SSO_ENABLED = true;
        SSO_ONLY = false;
        SSO_AUTHORITY = "https://auth.${publicDomain}";
      };
    };
  };
}
