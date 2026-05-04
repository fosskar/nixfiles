{
  flake.modules.nixos.authelia =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      serviceName = "auth";
      localHost = "${serviceName}.${config.domains.local}";
      publicHost = "${serviceName}.${config.domains.public}";
      listenAddress = "0.0.0.0";
      listenPort = 9091;
      listenUrl = "http://127.0.0.1:${toString listenPort}";

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
              --common-name "${localHost}" \
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
              experimental_enable_passkey_upgrade = true;
              display_name = "Authelia";
              selection_criteria.discoverability = "required";
            };

            totp = {
              disable = false;
              issuer = config.domains.public;
              algorithm = "sha512";
              digits = 6;
              period = 30;
              skew = 1;
            };

            server.address = "tcp://${listenAddress}:${toString listenPort}";

            authentication_backend.ldap = {
              implementation = "lldap";
              address = "ldap://127.0.0.1:3890";
              base_dn = "dc=nixbox,dc=local";
              user = "uid=authelia,ou=people,dc=nixbox,dc=local";
            };

            session = {
              name = "authelia_session";
              same_site = "lax";
              expiration = "1w";
              inactivity = "1d";
              remember_me = "1M";
              cookies = [
                {
                  domain = config.domains.local;
                  authelia_url = "https://${localHost}";
                }
              ]
              ++ [
                {
                  domain = config.domains.public;
                  authelia_url = "https://${publicHost}";
                }
              ];
            };

            regulation = {
              max_retries = 3;
              find_time = "1h";
              ban_time = "1h";
            };

            access_control = {
              default_policy = "two_factor";
              rules = lib.mkAfter [
                {
                  domain = [ "*.${config.domains.local}" ];
                  subject = [ "group:user" ];
                  policy = "one_factor";
                }
              ];
            };

            definitions.user_attributes.immich_role.expression = ''"admin" in groups ? "admin" : "user"'';

            identity_providers.oidc.authorization_policies = {
              users = {
                default_policy = "deny";
                rules = [
                  {
                    policy = "two_factor";
                    subject = [
                      "group:user"
                      "group:admin"
                    ];
                  }
                ];
              };

              admins = {
                default_policy = "deny";
                rules = [
                  {
                    policy = "two_factor";
                    subject = [ "group:admin" ];
                  }
                ];
              };
            };

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

        services.homepage-dashboard.serviceGroups."Security" =
          lib.mkIf config.services.homepage-dashboard.enable
            [
              {
                "Authelia" = {
                  href = "https://${localHost}";
                  icon = "authelia.svg";
                  siteMonitor = listenUrl;
                };
              }
            ];

        services.gatus.settings.endpoints = lib.mkIf config.services.gatus.enable [
          {
            name = "Authelia";
            url = "https://${localHost}";
            group = "Security";
            enabled = true;
            interval = "5m";
            conditions = [ "[STATUS] == 200" ];
            alerts = [ { type = "ntfy"; } ];
          }
        ];

        services.caddy.virtualHosts.${localHost}.extraConfig = ''
          header Strict-Transport-Security "max-age=31536000; includeSubDomains"
          reverse_proxy ${listenUrl}
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
