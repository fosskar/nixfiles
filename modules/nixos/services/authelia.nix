{
  flake.modules.nixos.authelia =
    {
      flake-self,
      config,
      lib,
      pkgs,
      ...
    }:
    let
      serviceName = "auth";
      localHost = "${serviceName}.${flake-self.domains.local}";
      publicHost = "${serviceName}.${flake-self.domains.public}";
      listenAddress = "0.0.0.0";
      listenPort = 9091;
      listenUrl = "http://127.0.0.1:${toString listenPort}";

      secretsPermission = {
        secret = true;
        owner = "authelia-main";
        group = "authelia-main";
      };
      smtpEnabled = config.clan.core.vars.generators ? smtp;
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

          runtimeInputs = [
            pkgs.authelia
            pkgs.pwgen
            pkgs.openssl
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
              issuer = flake-self.domains.public;
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
              inactivity = "1w";
              remember_me = "1M";
              redis = {
                host = config.services.redis.servers.authelia.unixSocket;
                port = 0;
              };
              cookies = [
                {
                  domain = flake-self.domains.local;
                  authelia_url = "https://${localHost}";
                }
              ]
              ++ [
                {
                  domain = flake-self.domains.public;
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
                  domain = [ "*.${flake-self.domains.local}" ];
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

            notifier = lib.mkMerge [
              (lib.mkIf smtpEnabled {
                smtp = {
                  address = ''submission://{{ env "SMTP_HOST" }}:{{ env "SMTP_PORT" }}'';
                  username = ''{{ env "SMTP_USER" }}'';
                  password = ''{{ env "SMTP_PASSWORD" }}'';
                  sender = ''Authelia <{{ env "SMTP_FROM" }}>'';
                  identifier = config.networking.hostName;
                  subject = "[Authelia] {title}";
                  startup_check_address = ''{{ env "SMTP_FROM" }}'';
                };
              })
              (lib.mkIf (!smtpEnabled) {
                # notifier.filesystem.filename = "/var/lib/authelia-main/notifications.txt";
                filesystem.filename = "/var/lib/authelia-main/notifications.txt";
              })
            ];
          };
        };

        systemd.services.authelia-main.serviceConfig.EnvironmentFile =
          lib.mkIf smtpEnabled
            config.clan.core.vars.generators.smtp.files."smtp-env".path;

        services.redis.servers.authelia = {
          enable = true;
          user = "authelia-main";
        };

        services.homepage-dashboard.serviceGroups."security" = [
          {
            "Authelia" = {
              href = "https://${localHost}";
              icon = "authelia.svg";
              siteMonitor = listenUrl;
            };
          }
        ];

        services.gatus.settings.endpoints = [
          {
            name = "Authelia";
            url = "https://${localHost}";
            group = "Security";
            enabled = true;
            alerts = [ { type = "email"; } ];
            interval = "5m";
            conditions = [ "[STATUS] == 200" ];
          }
        ];

        services.caddy.virtualHosts.${localHost}.extraConfig = ''
          header {
            Strict-Transport-Security "max-age=31536000; includeSubDomains"
            X-Content-Type-Options "nosniff"
            X-Frame-Options "SAMEORIGIN"
            X-Robots-Tag "noindex, nofollow, nosnippet, noarchive"
            X-Download-Options "noopen"
            X-Permitted-Cross-Domain-Policies "none"
          }
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
