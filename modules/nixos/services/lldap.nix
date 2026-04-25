# lldap over file-based auth — user management via web UI,
# keeps personal data (family names etc.) out of nix store and git
{
  flake.modules.nixos.lldap =
    {
      config,
      domains,
      lib,
      pkgs,
      ...
    }:
    let
      serviceName = "ldap";
      localHost = "${serviceName}.${domains.local}";
      listenAddress = "127.0.0.1";
      listenPort = 17170;
      listenUrl = "http://${listenAddress}:${toString listenPort}";
    in
    {
      clan.core.vars.generators.lldap = {
        files = {
          "jwt-secret" = {
            secret = true;
            owner = "lldap";
            group = "lldap";
          };
          "password" = {
            secret = true;
            owner = "lldap";
            group = "lldap";
          };
          "envfile" = {
            secret = true;
            owner = "lldap";
            group = "lldap";
          };
        };

        runtimeInputs = [ pkgs.pwgen ];
        script = ''
          pwgen -s 64 1 | tr -d '\n' > "$out/jwt-secret"
          pwgen -s 32 1 | tr -d '\n' > "$out/password"

          KEYSEED="$(pwgen -s 32 1)"
          echo "LLDAP_KEY_SEED=$KEYSEED" > "$out/envfile"
        '';
      };

      users.users.lldap = {
        isSystemUser = true;
        group = "lldap";
        home = "/var/lib/lldap";
      };
      users.groups.lldap = { };

      services.lldap = {
        enable = true;

        settings = {
          ldap_base_dn = "dc=nixbox,dc=local";
          ldap_host = "127.0.0.1";
          ldap_listenPort = 3890;

          http_host = listenAddress;
          http_port = listenPort;
          http_url = "https://${localHost}";

          force_ldap_user_pass_reset = "always";

          jwt_secret_file = config.clan.core.vars.generators.lldap.files."jwt-secret".path;
          ldap_user_pass_file = config.clan.core.vars.generators.lldap.files."password".path;
        };

        environmentFile = config.clan.core.vars.generators.lldap.files."envfile".path;
      };

      services.homepage-dashboard.serviceGroups."Security" =
        lib.mkIf config.services.homepage-dashboard.enable
          [
            {
              "LLDAP" = {
                href = "https://${localHost}";
                icon = "lldap.png";
                siteMonitor = listenUrl;
              };
            }
          ];

      services.gatus.settings.endpoints = lib.mkIf config.services.gatus.enable [
        {
          name = "LLDAP";
          url = "https://${localHost}";
          group = "Security";
          enabled = true;
          interval = "5m";
          conditions = [ "[STATUS] == 200" ];
          alerts = [ { type = "ntfy"; } ];
        }
      ];

      services.caddy.virtualHosts.${localHost}.extraConfig = ''
        reverse_proxy ${listenUrl}
      '';

      clan.core.state.lldap = {
        folders = [ "/var/backup/lldap" ];
        preBackupScript = ''
          export PATH=${
            lib.makeBinPath [
              pkgs.sqlite
              pkgs.coreutils
            ]
          }
          mkdir -p /var/backup/lldap
          sqlite3 /var/lib/lldap/users.db ".backup '/var/backup/lldap/users.db'"
        '';
      };
    };
}
