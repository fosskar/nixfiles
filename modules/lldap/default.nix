# lldap over file-based auth — user management via web UI,
# keeps personal data (family names etc.) out of nix store and git
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.nixfiles.lldap;
  acmeDomain = config.nixfiles.caddy.domain;
  serviceDomain = "ldap.${acmeDomain}";
  bindAddress = "127.0.0.1";
  port = 17170;
  internalUrl = "http://${bindAddress}:${toString port}";
in
{
  # --- options ---

  options.nixfiles.lldap = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "lldap lightweight ldap server";
    };

    sssd = {
      enable = lib.mkEnableOption "sssd ldap → posix identity provider";
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      # --- secrets ---

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

      # --- service ---

      # create lldap user/group before secrets are installed
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
          ldap_port = 3890;

          http_host = bindAddress;
          http_port = port;
          http_url = "https://${serviceDomain}";

          force_ldap_user_pass_reset = "always";

          jwt_secret_file = config.clan.core.vars.generators.lldap.files."jwt-secret".path;
          ldap_user_pass_file = config.clan.core.vars.generators.lldap.files."password".path;
        };

        environmentFile = config.clan.core.vars.generators.lldap.files."envfile".path;
      };

      # --- homepage ---

      nixfiles.homepage.entries = lib.mkIf config.services.homepage-dashboard.enable [
        {
          name = "LLDAP";
          category = "Security";
          icon = "lldap.png";
          href = "https://${serviceDomain}";
          siteMonitor = internalUrl;
        }
      ];

      # --- gatus ---

      nixfiles.gatus.endpoints = lib.mkIf config.nixfiles.gatus.enable [
        {
          name = "LLDAP";
          url = "https://${serviceDomain}";
          group = "Security";
        }
      ];

      # --- caddy ---

      nixfiles.caddy.vhosts.ldap = {
        inherit port;
      };

      # --- backup ---

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
    })
  ];
}
