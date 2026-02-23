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
  baseDn = "dc=nixbox,dc=local";
in
{
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
    })

    # sssd: resolve lldap users/groups as posix identities
    (lib.mkIf cfg.sssd.enable {
      services.sssd = {
        enable = true;
        environmentFile = config.clan.core.vars.generators.sssd.files."envfile".path;
        settings = {
          sssd = {
            services = "nss, pam";
            domains = "nixbox";
          };
          nss = {
            filter_users = "root";
            filter_groups = "root";
          };
          pam = {
            offline_failed_login_attempts = 3;
            offline_failed_login_delay = 5;
          };
          "domain/nixbox" = {
            id_provider = "ldap";
            auth_provider = "ldap";
            chpass_provider = "ldap";
            access_provider = "permit";

            # lldap does not support some filters sssd uses for enumeration refresh
            enumerate = false;
            cache_credentials = true;

            # localhost lldap via plain ldap (no starttls)
            ldap_uri = "ldap://127.0.0.1:3890/";
            ldap_id_use_start_tls = false;
            ldap_tls_reqcert = "never";
            ldap_schema = "rfc2307bis";
            ldap_search_base = baseDn;

            # bind as admin (password via env substitution)
            ldap_default_bind_dn = "uid=admin,ou=people,${baseDn}";
            ldap_default_authtok = "$SSSD_LDAP_PASSWORD";

            # only resolve users/groups with posix attributes set
            ldap_user_search_base = "ou=people,${baseDn}?subtree?(uidNumber=*)";
            ldap_user_object_class = "posixAccount";
            ldap_user_name = "uid";
            ldap_user_gecos = "cn";
            ldap_user_uid_number = "uidNumber";
            ldap_user_gid_number = "gidNumber";
            ldap_user_home_directory = "homeDirectory";
            ldap_user_shell = "unixShell";

            ldap_group_search_base = "ou=groups,${baseDn}?subtree?(gidNumber=*)";
            ldap_group_object_class = "groupOfUniqueNames";
            ldap_group_name = "cn";
            ldap_group_gid_number = "gidNumber";
            ldap_group_member = "uniqueMember";
          };
        };
      };

      # sssd env file with lldap admin password
      clan.core.vars.generators.sssd = {
        dependencies = [ "lldap" ];
        files."envfile" = {
          secret = true;
        };
        script = ''
          PASSWORD=$(cat "$in/lldap/password")
          echo "SSSD_LDAP_PASSWORD=$PASSWORD" > "$out/envfile"
        '';
      };

      systemd.services.sssd = {
        after = [ "lldap.service" ];
        wants = [ "lldap.service" ];
      };
    })
  ];
}
