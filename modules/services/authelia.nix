{
  flake.modules.nixos.authelia =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      acmeDomain = "nx3.eu";
      publicDomain = "fosskar.eu";
      serviceDomain = "auth.${acmeDomain}";
      bindAddress = "0.0.0.0";
      port = 9091;
      internalUrl = "http://127.0.0.1:${toString port}";

      secretsPermission = {
        secret = true;
        owner = "authelia-main";
        group = "authelia-main";
      };
    in
    {
      config = {
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

          runtimeInputs = with pkgs; [
            authelia
            pwgen
            openssl
          ];
          script = ''
            pwgen -s 64 1 | tr -d '\n' > "$out/jwt-secret"
            pwgen -s 64 1 | tr -d '\n' > "$out/session-secret"
            pwgen -s 64 1 | tr -d '\n' > "$out/hmac-secret"
            pwgen -s 64 1 | tr -d '\n' > "$out/storage-encryption-key"
            pwgen -s 32 1 | tr -d '\n' > "$out/lldap-password"

            authelia crypto certificate rsa generate \
              --common-name "${serviceDomain}" \
              --bits 4096 \
              --file.private-key jwks-private-key \
              --file.certificate jwks-certificate \
              --directory "$out"
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
              issuer = publicDomain;
              algorithm = "sha512";
              digits = 6;
              period = 30;
              skew = 1;
            };

            server.address = "tcp://${bindAddress}:${toString port}";

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
              ++ [
                {
                  domain = publicDomain;
                  authelia_url = "https://auth.${publicDomain}";
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
              rules = [
                {
                  domain = [ "*.${acmeDomain}" ];
                  policy = "one_factor";
                }
              ];
            };

            definitions.user_attributes.immich_role.expression = ''"admin" in groups ? "admin" : "user"'';

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

        services.homepage-dashboard.services = lib.mkIf config.services.homepage-dashboard.enable [
          {
            "Security" = [
              {
                "Authelia" = {
                  href = "https://${serviceDomain}";
                  icon = "authelia.svg";
                  siteMonitor = internalUrl;
                };
              }
            ];
          }
        ];

        services.gatus.settings.endpoints = lib.mkIf config.services.gatus.enable [
          {
            name = "Authelia";
            url = "https://${serviceDomain}";
            group = "Security";
            enabled = true;
            interval = "5m";
            conditions = [ "[STATUS] == 200" ];
            alerts = [ { type = "ntfy"; } ];
          }
        ];

        services.caddy.virtualHosts."auth.nx3.eu".extraConfig = ''
          reverse_proxy 127.0.0.1:${toString port}
        '';

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
      };
    };
}
