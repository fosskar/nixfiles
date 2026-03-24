{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.nixfiles.beszel.hub;
  beszelDomain = "beszel.${config.nixfiles.caddy.domain}";
in
{
  options.nixfiles.beszel.hub = {
    enable = lib.mkEnableOption "beszel monitoring hub";

    environment = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
      description = "extra beszel hub environment variables";
    };
  };

  config = lib.mkIf cfg.enable {
    clan.core.vars.generators.beszel-oidc = {
      files."oauth-client-secret" = { };
      files."oauth-client-secret-hash" = {
        owner = "authelia-main";
        group = "authelia-main";
      };
      runtimeInputs = [
        pkgs.pwgen
        pkgs.authelia
      ];
      script = ''
        if [ ! -s "$out/oauth-client-secret" ] || [ ! -s "$out/oauth-client-secret-hash" ]; then
          secret=$(pwgen -s 64 1)
          authelia crypto hash generate pbkdf2 --password "$secret" | tail -1 | cut -d' ' -f2 > "$out/oauth-client-secret-hash"
          echo -n "$secret" > "$out/oauth-client-secret"
        fi
      '';
    };

    # --- backup ---

    clan.core.state.beszel-hub = {
      folders = [ "/var/backup/beszel-hub" ];
      preBackupScript = ''
        export PATH=${
          lib.makeBinPath [
            pkgs.sqlite
            pkgs.coreutils
          ]
        }
        mkdir -p /var/backup/beszel-hub
        sqlite3 /var/lib/beszel-hub/beszel_data/beszel.db ".backup '/var/backup/beszel-hub/beszel.db'"
        sqlite3 /var/lib/beszel-hub/beszel_data/data.db ".backup '/var/backup/beszel-hub/data.db'"
        sqlite3 /var/lib/beszel-hub/beszel_data/auxiliary.db ".backup '/var/backup/beszel-hub/auxiliary.db'"
      '';
    };

    services.authelia.instances.main.settings.identity_providers.oidc.clients = [
      {
        client_id = "beszel";
        client_name = "Beszel";
        client_secret = "{{ secret \"${
          config.clan.core.vars.generators.beszel-oidc.files."oauth-client-secret-hash".path
        }\" }}";
        public = false;
        authorization_policy = "two_factor";
        consent_mode = "implicit";
        require_pkce = true;
        pkce_challenge_method = "S256";
        redirect_uris = [ "https://${beszelDomain}/api/oauth2-redirect" ];
        scopes = [
          "openid"
          "email"
          "profile"
        ];
        response_types = [ "code" ];
        grant_types = [ "authorization_code" ];
        access_token_signed_response_alg = "none";
        userinfo_signed_response_alg = "none";
        token_endpoint_auth_method = "client_secret_basic";
      }
    ];

    services.beszel.hub = {
      enable = true;
      host = "127.0.0.1";
      port = 8090;
      inherit (cfg) environment;
    };
  };
}
