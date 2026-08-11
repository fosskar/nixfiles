_: {
  flake.clan.inventory.instances = {
    # backups

    # creates filesystem snapshots and exposes those snapshot paths as clan.core.state;
    # clan-core borgbackup consumes the state and performs the actual backup.
    snapshot-backup = {
      module = {
        name = "snapshot-backup";
        input = "self";
      };
      roles.client.machines = {
        "gateway".settings = {
          snapshotType = "btrfs";
          folders = [ "/persist" ];
        };
        "nixbox".settings = {
          snapshotType = "zfs";
          folders = [
            "/tank/apps"
            "/tank/backup"
            "/tank/shares"
          ];
        };
      };
    };

    borgbackup =
      let
        # borg anchors a bare path at the filesystem root, so "/var/log"
        # never matches inside a snapshot source like /persist/.borg-backup.
        # sh: enables **/, which matches at any depth; the bare globs below
        # already match at any depth under the default fnmatch style.
        exclude = [
          "sh:**/var/cache"
          "sh:**/var/log"
          "sh:**/var/tmp"
          "sh:**/var/lib/systemd/coredump"
          # raw cluster files; the per-database dumps in /var/backup/postgres
          # are the supported restore path
          "sh:**/var/lib/postgresql"
          "*.pyc"
          "*.o"
          "*/node_modules/*"
        ];
      in
      {
        module = {
          name = "borgbackup";
          input = "clan-core";
        };
        roles = {
          client = {
            machines = {
              "gateway".settings = {
                startAt = "*-*-* 04:00:00";
                # the sql dump in /var/backup/netbird-server is the consistent
                # copy; the live file is a 1 GB rolling access log, torn at
                # snapshot time and never restored from
                exclude = exclude ++ [
                  "sh:**/var/lib/netbird-server/store.db*"
                ];
                destinations = {
                  "storagebox" = {
                    repo = "ssh://u499127-sub1@u499127.your-storagebox.de:23/./gateway";
                  };
                };
              };
              "nixbox".settings = {
                startAt = "*-*-* 03:00:00";
                inherit exclude;
                destinations = {
                  "storagebox" = {
                    repo = "ssh://u499127-sub1@u499127.your-storagebox.de:23/./nixbox";
                  };
                };
              };
            };
          };
          server.machines = { };
        };
      };
  };
}
