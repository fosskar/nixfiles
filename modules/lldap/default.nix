{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.nixfiles.lldap;
  acmeDomain = config.nixfiles.acme.domain;
  serviceDomain = "ldap.${acmeDomain}";
in
{
  options.nixfiles.lldap = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "lldap lightweight ldap server";
    };
  };

  config = lib.mkIf cfg.enable {
    # create lldap user/group before secrets are installed
    users.users.lldap = {
      isSystemUser = true;
      group = "lldap";
      home = "/var/lib/lldap";
    };
    users.groups.lldap = { };

    # generate lldap secrets via clan vars
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

    services.lldap = {
      enable = true;

      settings = {
        ldap_base_dn = "dc=nixbox,dc=local";

        ldap_host = "127.0.0.1";
        ldap_port = 3890;

        http_host = "127.0.0.1";
        http_port = 17170;
        http_url = "https://${serviceDomain}";

        force_ldap_user_pass_reset = "always";

        jwt_secret_file = config.clan.core.vars.generators.lldap.files."jwt-secret".path;
        ldap_user_pass_file = config.clan.core.vars.generators.lldap.files."password".path;
      };

      environmentFile = config.clan.core.vars.generators.lldap.files."envfile".path;
    };

    # nginx reverse proxy
    nixfiles.nginx.vhosts.ldap = {
      port = 17170;
    };

    # sqlite backup for borgbackup
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
