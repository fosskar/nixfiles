_: {
  disko.devices = {
    disk = {
      # optane drive 1 (16gb) - primary boot + slog
      optane1 = {
        type = "disk";
        device = "/dev/disk/by-id/nvme-INTEL_MEMPEK1J016GA_PHBT83620341016N";
        content = {
          type = "gpt";
          partitions = {
            esp = {
              size = "1G";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [
                  "defaults"
                  "umask=0077"
                ];
              };
            };
            slog = {
              size = "100%";
              type = "BF01";
              # slog for tank pool (added manually, documented here)
              content = {
                type = "zfs";
                pool = "tank";
              };
            };
          };
        };
      };

      # optane drive 2 (16gb) - fallback boot + slog mirror
      optane2 = {
        type = "disk";
        device = "/dev/disk/by-id/nvme-INTEL_MEMPEK1J016GA_PHBT836304CV016N";
        content = {
          type = "gpt";
          partitions = {
            esp = {
              size = "1G";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot-fallback";
                mountOptions = [
                  "defaults"
                  "umask=0077"
                ];
              };
            };
            slog = {
              size = "100%";
              type = "BF01";
              # slog mirror for tank pool (added manually, documented here)
              content = {
                type = "zfs";
                pool = "tank";
              };
            };
          };
        };
      };

      # flash ssd 1 (1tb)
      flash1 = {
        type = "disk";
        device = "/dev/disk/by-id/ata-KINGSTON_SEDC600M960G_50026B768755993B";
        content = {
          type = "gpt";
          partitions = {
            zfs = {
              size = "100%";
              content = {
                type = "zfs";
                pool = "znixos";
              };
            };
          };
        };
      };

      # flash ssd 2 (1tb) - mirror
      flash2 = {
        type = "disk";
        device = "/dev/disk/by-id/ata-KINGSTON_SEDC600M960G_50026B7687522C31";
        content = {
          type = "gpt";
          partitions = {
            zfs = {
              size = "100%";
              content = {
                type = "zfs";
                pool = "znixos";
              };
            };
          };
        };
      };
    };

    zpool = {
      znixos = {
        type = "zpool";
        mode = "mirror";
        options = {
          ashift = "12";
          autotrim = "on";
        };
        rootFsOptions = {
          compression = "zstd";
          atime = "off";
          acltype = "posixacl";
          mountpoint = "none";
        };
        datasets = {
          root = {
            type = "zfs_fs";
            options.mountpoint = "legacy";
            mountpoint = "/";
            options."com.sun:auto-snapshot" = "false";
            postCreateHook = "zfs snapshot znixos/root@blank";
          };
          nix = {
            type = "zfs_fs";
            options.mountpoint = "legacy";
            mountpoint = "/nix";
            options."com.sun:auto-snapshot" = "false";
          };
          persist = {
            type = "zfs_fs";
            options.mountpoint = "legacy";
            mountpoint = "/persist";
            options."com.sun:auto-snapshot" = "true";
          };
          reserved = {
            type = "zfs_fs";
            options = {
              mountpoint = "none";
              refreservation = "20G";
            };
          };
        };
      };
    };
  };
}
