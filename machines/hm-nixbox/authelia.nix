{
  config,
  pkgs,
  ...
}:
{
  # generate authelia secrets via clan vars
  clan.core.vars.generators.authelia = {
    files."jwt-secret" = {
      secret = true;
      owner = "authelia-main";
    };
    files."storage-encryption-key" = {
      secret = true;
      owner = "authelia-main";
    };
    files."oidc-hmac-secret" = {
      secret = true;
      owner = "authelia-main";
    };
    files."oidc-issuer-private-key" = {
      secret = true;
      owner = "authelia-main";
    };
    files."pangolin-client-secret" = {
      secret = true;
    };

    runtimeInputs = with pkgs; [
      coreutils
      openssl
    ];
    script = ''
      gensecret() {
        openssl rand 64 | openssl base64 -A | tr '+/' '-_' | tr -d '='
      }
      gensecret > "$out/jwt-secret"
      gensecret > "$out/storage-encryption-key"
      gensecret > "$out/oidc-hmac-secret"
      openssl genrsa -out "$out/oidc-issuer-private-key" 4096
      gensecret > "$out/pangolin-client-secret"
    '';
  };

  services.authelia.instances.main = {
    enable = true;

    secrets = {
      jwtSecretFile = config.clan.core.vars.generators.authelia.files."jwt-secret".path;
      storageEncryptionKeyFile =
        config.clan.core.vars.generators.authelia.files."storage-encryption-key".path;
      oidcHmacSecretFile = config.clan.core.vars.generators.authelia.files."oidc-hmac-secret".path;
      oidcIssuerPrivateKeyFile =
        config.clan.core.vars.generators.authelia.files."oidc-issuer-private-key".path;
    };

    # ldap bind password via environment file
    environmentVariables = {
      AUTHELIA_AUTHENTICATION_BACKEND_LDAP_PASSWORD_FILE = config.sops.secrets."admin-password".path;
    };

    settings = {
      theme = "dark";
      default_2fa_method = "totp";

      webauthn = {
        disable = false;
        enable_passkey_login = true;
        display_name = "Authelia";
        attestation_conveyance_preference = "indirect";
        timeout = "60s";
      };

      server.address = "tcp://127.0.0.1:9091";

      authentication_backend.ldap = {
        implementation = "lldap";
        address = "ldap://127.0.0.1:3890";
        base_dn = "dc=nixbox,dc=local";
        user = "uid=admin,ou=people,dc=nixbox,dc=local";
      };

      session.cookies = [
        {
          domain = "osscar.me";
          authelia_url = "https://auth.osscar.me";
        }
      ];

      access_control = {
        default_policy = "two_factor";
      };

      storage.local.path = "/var/lib/authelia-main/db.sqlite3";

      notifier.filesystem.filename = "/var/lib/authelia-main/notifications.txt";

      identity_providers.oidc = {
        # custom claims policy for pangolin (has oidc bugs per authelia docs)
        claims_policies.pangolin = {
          id_token = [
            "rat"
            "groups"
            "email"
            "email_verified"
            "alt_emails"
            "preferred_username"
            "name"
          ];
        };

        clients = [
          {
            client_id = "pangolin";
            client_name = "Pangolin";
            client_secret = "$pbkdf2-sha512$310000$rc7yjLy4bVzRFaLrDuVznA$66QAlNEcjvNhqg96ltKMrWaVa1ysHfrX6fgp8VhxHwU4zts1I0Atjk5YdsnM.wAet2E./f1lryCZxY7HAeLKuw";
            public = false;
            authorization_policy = "two_factor";
            claims_policy = "pangolin";
            redirect_uris = [ "https://pango.osscar.me/auth/idp/1/oidc/callback" ];
            scopes = [
              "openid"
              "profile"
              "email"
              "groups"
            ];
            token_endpoint_auth_method = "client_secret_basic";
            pkce_challenge_method = "S256";
          }
        ];
      };
    };
  };
}
