{
  config,
  lib,
  pkgs,
  ...
}:
{
  # enable sssd for posix identity from lldap
  nixfiles.lldap.sssd.enable = true;

  # optional smb passdb sync input (plaintext passwords, separate from lldap)
  # format: one line per user -> username:password
  clan.core.vars.generators.samba = {
    files."users" = {
      secret = true;
    };
    script = ''
      cat > "$out/users" <<'EOF'
      # username:password
      EOF
    '';
  };

  # create home dirs on first auth/session for ldap users ([homes] share)
  security.pam.services.samba.makeHomeDir = true;

  # shared dir is static; personal dirs come from [homes] + pam_mkhomedir
  systemd.tmpfiles.rules = [
    "d /tank/shares/shared 2775 root shared -"
  ];

  system.activationScripts.createSharedSubdirs = lib.stringAfter [ "users" "groups" ] ''
    install -d -m 2775 -o root -g shared /tank/shares/shared/documents
  '';

  # shared group must exist for directory ownership (sssd provides it at runtime,
  # but tmpfiles/activation run before sssd — keep a static fallback)
  users.groups.shared = {
    gid = 3030;
  };

  services = {
    samba = {
      enable = true;
      openFirewall = true;
      nmbd.enable = false;
      winbindd.enable = false;
      settings = {
        global = {
          "server string" = "smbnix";
          "server role" = "standalone server";
          "workgroup" = "WORKGROUP";
          security = "user";

          # identity lookup via nss/sssd; smb passwords still use samba passdb
          "obey pam restrictions" = "yes";
          "pam password change" = "yes";

          # disable netbios (not needed, clients use direct ip/hostname)
          "disable netbios" = "yes";
          "dns proxy" = false;

          "log level" = "0 auth:2 passdb:2";
          "log file" = "/dev/null";
          "max log size" = "0";
          "logging" = "systemd";

          "hosts allow" = "127.0.0.0/8 192.168.10.0/24";
          "hosts deny" = "0.0.0.0/0";
          "name resolve order" = "bcast host";

          "guest account" = "nobody";
          "map to guest" = "never";
          "access based share enum" = "yes";

          "server min protocol" = "SMB3_11";
          "server smb encrypt" = "required";

          "map archive" = "no";
          "map system" = "no";
          "map hidden" = "no";

          "load printers" = "no";
          "printing" = "bsd";
          "printcap name" = "/dev/null";
          "disable spoolss" = "yes";
          "show add printer wizard" = "no";

          "vfs objects" = "catia fruit streams_xattr recycle";
          "fruit:aapl" = "yes";
          "fruit:wipe_intentionally_left_blank_rfork" = "yes";
          "fruit:delete_empty_adfiles" = "yes";
          "recycle:repository" = ".recycle";
          "recycle:keeptree" = "yes";
          "recycle:versions" = "yes";
          "recycle:touch" = "yes";
          "recycle:exclude" = "*.tmp,*.temp,*.log,*.cache";
          "recycle:exclude_dir" = ".recycle,.cache,tmp,.Trash-*";
          "recycle:maxsize" = "0";
        };
      }
      // {
        homes = {
          browseable = "no";
          "read only" = "no";
          "guest ok" = "no";
          "create mask" = "0600";
          "directory mask" = "0700";
          "valid users" = "%S";
          "delete readonly" = "no";
          comment = "personal folder";
        };
        shared = {
          path = "/tank/shares/shared";
          browseable = "yes";
          "read only" = "no";
          "guest ok" = "no";
          "create mask" = "0664";
          "directory mask" = "2775";
          "force group" = "shared";
          "delete readonly" = "no";
          comment = "shared folder";
        };
      };
    };

    samba-wsdd = {
      enable = true;
      openFirewall = true;
    };

    # mdns/bonjour for mac/ios discovery
    avahi = {
      enable = true;
      openFirewall = true;
      publish = {
        enable = true;
        userServices = true;
      };
    };
  };

  systemd.services.samba-passdb-sync = {
    description = "sync samba passdb from clan var file";
    after = [
      "sssd.service"
      "samba-smbd.service"
      "sops-install-secrets.service"
    ];
    wants = [
      "sssd.service"
      "samba-smbd.service"
      "sops-install-secrets.service"
    ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      set -euo pipefail

      pwfile=${config.clan.core.vars.generators.samba.files."users".path}

      # no file yet -> no-op until you populate clan vars
      [ -e "$pwfile" ] || exit 0

      timeout=15
      while [ "$timeout" -gt 0 ]; do
        [ -f /var/lib/samba/private/secrets.tdb ] && break
        sleep 1
        timeout=$((timeout - 1))
      done
      [ "$timeout" -gt 0 ] || { echo "samba db not ready" >&2; exit 1; }

      while IFS=: read -r user password rest || [ -n "''${user:-}" ]; do
        [ -n "''${user:-}" ] || continue
        case "$user" in
          \#*) continue ;;
        esac
        [ -n "''${password:-}" ] || { echo "missing password for $user" >&2; exit 1; }
        [ -z "''${rest:-}" ] || { echo "invalid line for $user (extra colon)" >&2; exit 1; }

        ${pkgs.getent}/bin/getent passwd "$user" >/dev/null || {
          echo "warning: missing linux user via sssd: $user" >&2
          continue
        }

        ${pkgs.coreutils}/bin/printf "%s\n%s\n" "$password" "$password" | \
          ${lib.getExe' pkgs.samba "smbpasswd"} -s -a "$user" >/dev/null
      done < "$pwfile"
    '';
  };
}
