{
  pkgs,
  lib,
  config,
  ...
}:
let
  # get user list from users.nix (list of { name, uid })
  sambaUsers = config.fileserverUsers;

  # simple helper to create personal share config
  mkPersonalShare =
    user:
    lib.nameValuePair user.name {
      path = "/mnt/shares/${user.name}";
      browseable = "yes"; # show in share list (access still restricted by valid users)
      "read only" = "no";
      "guest ok" = "no";
      "create mask" = "0640"; # files: owner read/write, group (storage_shared) read
      "directory mask" = "0750"; # dirs: owner full, group read+execute
      "force user" = user.name;
      "force group" = "storage_shared";
      "valid users" = user.name;
      # prevent deletion of read-only files (including the share root if mounted read-only)
      "delete readonly" = "no";
      comment = "personal folder";
    };

  # auto-generate all personal shares
  personalShares = builtins.listToAttrs (map mkPersonalShare sambaUsers);

in
{
  services = {
    samba = {
      enable = true;
      openFirewall = true;
      #package = pkgs.samba4Full;
      # disable nmbd (netbios name service) since netbios is disabled
      nmbd.enable = false;
      # disable winbindd (not needed for standalone server)
      winbindd.enable = false;
      settings = {
        global = {
          "server string" = "smbnix";
          # disable netbios since clients hardcode server address
          "disable netbios" = "yes";
          "server role" = "standalone server";
          "workgroup" = "WORKGROUP";
          "dns proxy" = false;

          # set sane logging options
          "log level" = "0 auth:2 passdb:2";
          "log file" = "/dev/null";
          "max log size" = "0";
          "logging" = "systemd";

          # allow local networks and tailscale
          "hosts allow" = "127.0.0.0/8 10.0.0.0/8 172.16.0.0/12 192.168.0.0/16 100.64.0.0/10";
          "hosts deny" = "0.0.0.0/0";
          "name resolve order" = "bcast host";

          "guest account" = "nobody";
          "map to guest" = "never";
          "access based share enum" = "yes";

          "server min protocol" = "SMB3_11";
          "server smb encrypt" = "required";

          # never map anything to the excutable bit
          "map archive" = "no";
          "map system" = "no";
          "map hidden" = "no";

          # disable printer sharing
          "load printers" = "no";
          "printing" = "bsd";
          "printcap name" = "/dev/null";
          "disable spoolss" = "yes";
          "show add printer wizard" = "no";

          # mac support and recycle bin
          "vfs objects" = "catia fruit streams_xattr recycle";
          # apple smb extensions
          "fruit:aapl" = "yes";
          "fruit:wipe_intentionally_left_blank_rfork" = "yes";
          "fruit:delete_empty_adfiles" = "yes";
          # recycle bin config - per-user trash
          "recycle:repository" = ".recycle";
          "recycle:keeptree" = "yes";
          "recycle:versions" = "yes";
          "recycle:touch" = "yes";
          "recycle:exclude" = "*.tmp,*.temp,*.log,*.cache";
          "recycle:exclude_dir" = ".recycle,.cache,tmp,.Trash-*";
          "recycle:maxsize" = "0";
        };
        # auto-generated personal shares (browseable = no, only owner can access)
      }
      // personalShares
      // {
        # shared folder - special handling
        shared = {
          path = "/mnt/shares/shared";
          browseable = "yes";
          "read only" = "no";
          "guest ok" = "no";
          "create mask" = "0664";
          "directory mask" = "2775"; # sticky bit (2) prevents users from deleting others' files
          "force group" = "shared";
          # prevent deletion of read-only files
          "delete readonly" = "no";
          comment = "shared folder for all users";
        };
      };
    };
    samba-wsdd = {
      enable = true;
      openFirewall = true;
      workgroup = "WORKGROUP";
    };
  };

  # create systemd services to add/update samba users after samba starts
  systemd.services = lib.mkMerge (
    map (user: {
      "samba-user-${user.name}" = {
        description = "add samba user ${user.name}";
        after = [ "samba-smbd.service" ];
        wants = [ "samba-smbd.service" ];
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
        script = ''
          # wait for samba database to be ready
          timeout=10
          while [ $timeout -gt 0 ]; do
            if [ -f /var/lib/samba/private/secrets.tdb ]; then
              break
            fi
            sleep 1
            ((timeout--))
          done

          if [ $timeout -eq 0 ]; then
            echo "ERROR: samba database not ready after 10 seconds" >&2
            exit 1
          fi

          # add or update samba user ${user.name} (UID ${toString user.uid})
          password=$(${pkgs.gnugrep}/bin/grep "^${user.name}:" ${
            config.age.secrets."fileserver-passwords".path
          } | ${pkgs.coreutils}/bin/cut -d: -f2)
          if [ -z "$password" ]; then
            echo "ERROR: No password found for user ${user.name}" >&2
            exit 1
          fi
          ${pkgs.coreutils}/bin/printf "%s\n%s\n" "$password" "$password" | ${lib.getExe' pkgs.samba "smbpasswd"} -sa ${user.name}
        '';
      };
    }) sambaUsers
  );
}
