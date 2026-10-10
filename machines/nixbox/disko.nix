{
  config,
  lib,
  self,
  preservationDiskoPostMountHook,
  ...
}:
{
  imports = [
    self.modules.nixos.zfs
    self.modules.nixos.preservation
  ];

  preservation.rollback = {
    dataset = "znixos/root";
    poolImportService = "zfs-import-znixos.service";
  };

  boot = {
    # mirror grub install across both ESPs declared below.
    loader.grub.mirroredBoots = [
      {
        devices = [ "nodev" ];
        path = "/boot";
      }
      {
        devices = [ "nodev" ];
        path = "/boot-fallback";
      }
    ];
    # disko manages only the root pool on flash1/flash2. tank (raidz2 on the
    # four hdds, log mirror on the optane slog partitions below) was created
    # by hand; its datasets are legacy-mountpoint and declared in
    # nixfiles.zfs.datasets, so nixos generates zfs-import-tank.service plus
    # real .mount units;
    # services depend on them via RequiresMountsFor.
  };

  nixfiles.zfs.datasets = {
    # default for everything below; datasets opt out explicitly
    "tank".properties."com.sun:auto-snapshot" = "true";
    "tank/backup" = { };
    # only holds the per-app datasets, which set their own snapshot policy
    "tank/apps".properties."com.sun:auto-snapshot" = "false";
    # garage blocks are at most 1MiB (block_size) and replicated to nixworker;
    # snapshots would only pin deleted blocks. capacity in the garage layout
    # does not limit disk usage, so enforce it here. garage reads "1T" as
    # 10^12 bytes and zfs as 2^40, which leaves ~10% headroom
    "tank/apps/garage".properties = {
      recordsize = "1M";
      "com.sun:auto-snapshot" = "false";
      refquota = (lib.head config.services.garage.settings.data_dir).capacity;
    };
    # replaceable media; music is its own dataset with snapshots. the quota
    # keeps a runaway download queue from filling the pool
    "tank/media".properties = {
      "com.sun:auto-snapshot" = "false";
      refquota = "4T";
    };
    # own recordings and music that cannot be downloaded again
    "tank/media/music".properties."com.sun:auto-snapshot" = "true";
    # never mounted; holds space back so a full pool can still be cleaned up
    "tank/reserved" = {
      mountPoint = null;
      properties = {
        canmount = "off";
        refreservation = "500G";
        "com.sun:auto-snapshot" = "false";
      };
    };
    # protomaps planet download (~140G), rebuildable
    "tank/scratch".properties = {
      "com.sun:auto-snapshot" = "false";
      recordsize = "1M";
      refquota = "200G";
    };
  };

  disko.devices = {
    disk = {
      "optane1" = {
        type = "disk";
        device = "/dev/disk/by-id/nvme-INTEL_MEMPEK1J016GA_PHBT83620341016N";
        content = {
          type = "gpt";
          partitions = {
            "esp" = {
              size = "1G";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [ "umask=0077" ];
              };
            };
            "slog" = {
              size = "100%";
              type = "BF01";
              content = {
                type = "zfs";
                pool = "tank";
              };
            };
          };
        };
      };
      "optane2" = {
        type = "disk";
        device = "/dev/disk/by-id/nvme-INTEL_MEMPEK1J016GA_PHBT836304CV016N";
        content = {
          type = "gpt";
          partitions = {
            "esp" = {
              size = "1G";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot-fallback";
                mountOptions = [ "umask=0077" ];
              };
            };
            "slog" = {
              size = "100%";
              type = "BF01";
              content = {
                type = "zfs";
                pool = "tank";
              };
            };
          };
        };
      };

      # flash ssd 1 (1tb)
      "flash1" = {
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
      "flash2" = {
        type = "disk";
        device = "/dev/disk/by-id/ata-KINGSTON_SEDC600M960G_50026B7687522C31";
        content = {
          type = "gpt";
          partitions = {
            "zfs" = {
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

    "zpool" = {
      znixos = {
        type = "zpool";
        mode = "mirror";
        options = {
          ashift = "12";
          autotrim = "on";
        };
        rootFsOptions = {
          compression = "zstd";
          acltype = "posixacl";
          mountpoint = "none";
        };
        datasets = {
          "root" = {
            type = "zfs_fs";
            options.mountpoint = "legacy";
            mountpoint = "/";
            options."com.sun:auto-snapshot" = "false";
            postCreateHook = "zfs snapshot znixos/root@blank";
          };
          "nix" = {
            type = "zfs_fs";
            options.mountpoint = "legacy";
            mountpoint = "/nix";
            options."com.sun:auto-snapshot" = "false";
          };
          "persist" = {
            type = "zfs_fs";
            options.mountpoint = "legacy";
            mountpoint = "/persist";
            options."com.sun:auto-snapshot" = "true";
            postMountHook = preservationDiskoPostMountHook;
          };
          "reserved" = {
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
