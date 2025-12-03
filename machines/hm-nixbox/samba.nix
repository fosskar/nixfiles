{
  pkgs,
  lib,
  config,
  ...
}:
let
  users = [
    {
      name = "simon";
      uid = 3000;
    }
    {
      name = "ina";
      uid = 3001;
    }
  ];

  mkShare =
    u:
    lib.nameValuePair u.name {
      path = "/tank/shares/${u.name}";
      browseable = "yes";
      "read only" = "no";
      "guest ok" = "no";
      "create mask" = "0600";
      "directory mask" = "0700";
      "force user" = u.name;
      "valid users" = u.name;
      "delete readonly" = "no";
      comment = "personal folder";
    };
in
{
  users = {
    groups.shared = { };

    users = lib.listToAttrs (
      map (
        u:
        lib.nameValuePair u.name {
          inherit (u) uid;
          description = "samba user";
          group = "shared";
          isSystemUser = true;
        }
      ) users
    );
  };

  systemd.tmpfiles.rules = [
    "d /tank/shares/shared 2775 root shared -"
  ]
  ++ map (u: "d /tank/shares/${u.name} 0700 ${u.name} - -") users;

  system.activationScripts.createUserShareSubdirs = lib.stringAfter [ "users" "groups" ] ''
    install -d -m 2775 -o root -g shared /tank/shares/shared/documents
    ${lib.concatMapStringsSep "\n" (u: ''
      install -d -m 0700 -o ${u.name} /tank/shares/${u.name}/pictures
      install -d -m 0700 -o ${u.name} /tank/shares/${u.name}/documents
    '') users}
  '';

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
      // lib.listToAttrs (map mkShare users)
      // {
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
      nssmdns4 = true;
      publish = {
        enable = true;
        userServices = true;
      };
    };
  };

  systemd.services = lib.mkMerge (
    map (u: {
      "samba-user-${u.name}" = {
        description = "add samba user ${u.name}";
        after = [ "samba-smbd.service" ];
        wants = [ "samba-smbd.service" ];
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
        script = ''
          timeout=10
          while [ $timeout -gt 0 ]; do
            [ -f /var/lib/samba/private/secrets.tdb ] && break
            sleep 1
            ((timeout--))
          done
          [ $timeout -eq 0 ] && { echo "ERROR: samba database not ready" >&2; exit 1; }

          password=$(${pkgs.gnugrep}/bin/grep "^${u.name}:" ${
            config.sops.secrets."samba-user-passwords".path
          } | ${pkgs.coreutils}/bin/cut -d: -f2)
          [ -z "$password" ] && { echo "ERROR: no password for ${u.name}" >&2; exit 1; }
          ${pkgs.coreutils}/bin/printf "%s\n%s\n" "$password" "$password" | ${lib.getExe' pkgs.samba "smbpasswd"} -sa ${u.name}
        '';
      };
    }) users
  );
}
