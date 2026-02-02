{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.nixfiles.authelia;
  acmeDomain = config.nixfiles.acme.domain;
  serviceDomain = "auth.${acmeDomain}";
  listenPort = 9091;

  secretsPermission = {
    secret = true;
    owner = "authelia-main";
    group = "authelia-main";
  };
in
{
  options.nixfiles.authelia = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "authelia sso portal with oidc and auth proxy";
    };

    publicDomain = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "simonoscar.me";
      description = "additional public domain for remote access (e.g. via pangolin tunnel)";
    };
  };

  config = lib.mkIf cfg.enable {
    # storage encryption key - separate generator, must never regenerate
    clan.core.vars.generators.authelia-storage-encryption-key = {
      files."storage-encryption-key" = secretsPermission;

      runtimeInputs = [ pkgs.pwgen ];
      script = ''
        pwgen -s 64 1 | tr -d '\n' > "$out/storage-encryption-key"
      '';
    };

    # main authelia secrets generator
    clan.core.vars.generators.authelia = {
      files = {
        "jwt-secret" = secretsPermission;
        "session-secret" = secretsPermission;
        "hmac-secret" = secretsPermission;
        "jwks-private-key" = secretsPermission;
        "jwks-certificate" = secretsPermission;
        "lldap-password" = secretsPermission;
        "storage-encryption-key" = secretsPermission;
      };

      dependencies = [ "authelia-storage-encryption-key" ];

      runtimeInputs = with pkgs; [
        authelia
        pwgen
        openssl
      ];
      script = ''
        pwgen -s 64 1 | tr -d '\n' > "$out/jwt-secret"
        pwgen -s 64 1 | tr -d '\n' > "$out/session-secret"
        pwgen -s 64 1 | tr -d '\n' > "$out/hmac-secret"
        pwgen -s 32 1 | tr -d '\n' > "$out/lldap-password"

        authelia crypto certificate rsa generate \
          --common-name "${serviceDomain}" \
          --bits 4096 \
          --file.private-key jwks-private-key \
          --file.certificate jwks-certificate \
          --directory "$out"

        cat "$in/authelia-storage-encryption-key/storage-encryption-key" > "$out/storage-encryption-key"
      '';
    };

    # sqlite backup for borgbackup
    clan.core.state.authelia = {
      folders = [ "/var/backup/authelia" ];
      preBackupScript = ''
        export PATH=${
          lib.makeBinPath [
            pkgs.sqlite
            pkgs.coreutils
          ]
        }
        mkdir -p /var/backup/authelia
        sqlite3 /var/lib/authelia-main/db.sqlite3 ".backup '/var/backup/authelia/db.sqlite3'"
      '';
    };

    services.authelia.instances.main = {
      enable = true;

      secrets = {
        jwtSecretFile = config.clan.core.vars.generators.authelia.files."jwt-secret".path;
        sessionSecretFile = config.clan.core.vars.generators.authelia.files."session-secret".path;
        storageEncryptionKeyFile =
          config.clan.core.vars.generators.authelia.files."storage-encryption-key".path;
        oidcHmacSecretFile = config.clan.core.vars.generators.authelia.files."hmac-secret".path;
        oidcIssuerPrivateKeyFile = config.clan.core.vars.generators.authelia.files."jwks-private-key".path;
      };

      environmentVariables = {
        AUTHELIA_AUTHENTICATION_BACKEND_LDAP_PASSWORD_FILE =
          config.clan.core.vars.generators.authelia.files."lldap-password".path;
        X_AUTHELIA_CONFIG_FILTERS = "template";
      };

      settings = {
        theme = "dark";
        default_2fa_method = "totp";

        webauthn = {
          disable = false;
          enable_passkey_login = true;
          experimental_enable_passkey_uv_two_factors = true;
          display_name = "Authelia";
        };

        totp = {
          disable = false;
          issuer = if cfg.publicDomain != null then cfg.publicDomain else acmeDomain;
          algorithm = "sha512";
          digits = 6;
          period = 30;
          skew = 1;
        };

        server.address = "tcp://127.0.0.1:${toString listenPort}";

        authentication_backend.ldap = {
          implementation = "lldap";
          address = "ldap://127.0.0.1:3890";
          base_dn = "dc=nixbox,dc=local";
          user = "uid=authelia,ou=people,dc=nixbox,dc=local";
        };

        session = {
          name = "authelia_session";
          same_site = "lax";
          expiration = "1h";
          inactivity = "5m";
          remember_me = "1M";
          cookies = [
            {
              domain = acmeDomain;
              authelia_url = "https://${serviceDomain}";
            }
          ]
          ++ lib.optionals (cfg.publicDomain != null) [
            {
              domain = cfg.publicDomain;
              authelia_url = "https://auth.${cfg.publicDomain}";
            }
          ];
        };

        regulation = {
          max_retries = 3;
          find_time = "2m";
          ban_time = "5m";
        };

        access_control = {
          default_policy = "two_factor";
        };

        # custom user attribute for immich admin mapping
        definitions.user_attributes.immich_role.expression = ''"admin" in groups ? "admin" : "user"'';

        # claims policy that exposes the attribute
        identity_providers.oidc.claims_policies.immich_policy.custom_claims.immich_role.attribute =
          "immich_role";

        identity_validation.elevated_session = {
          require_second_factor = true;
          code_lifespan = "5m";
          elevation_lifespan = "10m";
        };

        storage.local.path = "/var/lib/authelia-main/db.sqlite3";

        notifier.filesystem.filename = "/var/lib/authelia-main/notifications.txt";
      };
    };

    # nginx reverse proxy (always create for local domain)
    nixfiles.nginx.vhosts.auth.port = listenPort;
  };
}
