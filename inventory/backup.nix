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
        "ha-green".settings = {
          snapshotType = "btrfs";
          folders = [ "/persist" ];
        };
        "nixbox".settings = {
          snapshotType = "zfs";
          folders = [
            "/tank/apps/immich"
            "/tank/apps/opencloud"
            "/tank/backup"
            "/tank/media/music"
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
            # clan-core's restore pipes `y` into borg, which would also accept a
            # repository swapped for an unknown unencrypted one; answer no here
            extraModules = [
              {
                services.borgbackup.jobs.storagebox.environment.BORG_UNKNOWN_UNENCRYPTED_REPO_ACCESS_IS_OK = "no";
              }
              # /root is wiped on boot on preservation hosts; a lost cache makes the
              # next run re-read every file. StateDirectory is writable under the
              # job's ProtectSystem=strict
              {
                services.borgbackup.jobs.storagebox.environment.BORG_BASE_DIR = "/var/lib/borgbackup";
                systemd.services.borgbackup-job-storagebox.serviceConfig = {
                  # the root pre-backup hooks write database dumps; "+" does not
                  # exempt UMask, so new dumps and staging dirs are root-only
                  UMask = "0077";
                  StateDirectory = "borgbackup";
                  StateDirectoryMode = "0700";
                };
              }
              # host key published at https://docs.hetzner.com/storage/storage-box/general/
              # (SHA256:XqONwb1S0zuj5A1CDxpOSuD2hnAArV1A3wKY7Z3sdgM); without it the
              # job's accept-new trusts whatever answers after /root is wiped
              {
                programs.ssh.knownHosts.storagebox = {
                  hostNames = [ "[u499127.your-storagebox.de]:23" ];
                  publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIICf9svRenC/PLKIL9nk6K/pxQgoiFC41wTNvoIncOxs";
                };
              }
              (
                { lib, ... }:
                {
                  services.grafana.provision.alerting.rules.settings.groups = lib.importJSON ./backup.alerts.json;
                }
              )
            ];
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
                exclude = exclude ++ [
                  # regenerable media; originals remain backed up: https://docs.immich.app/administration/backup-and-restore/#filesystem
                  "sh:**/tank/apps/immich/encoded-video"
                  "sh:**/tank/apps/immich/thumbs"
                ];
                destinations = {
                  "storagebox" = {
                    repo = "ssh://u499127-sub1@u499127.your-storagebox.de:23/./nixbox";
                  };
                };
              };
              "ha-green".settings = {
                startAt = "*-*-* 06:00:00";
                inherit exclude;
                destinations = {
                  "storagebox" = {
                    repo = "ssh://u499127-sub1@u499127.your-storagebox.de:23/./ha-green";
                  };
                };
              };
              "nixworker".settings = {
                startAt = "*-*-* 05:00:00";
                inherit exclude;
                destinations = {
                  "storagebox" = {
                    repo = "ssh://u499127-sub1@u499127.your-storagebox.de:23/./nixworker";
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
