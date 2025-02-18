{ inputs, ... }:
{
  imports = [ inputs.disko.nixosModules.disko ];

  disko.devices = {
    disk = {
      one = {
        type = "disk";
        device = "/dev/nvme0n1";
        content = {
          type = "gpt";
          partitions = {
            BOOT = {
              size = "1M";
              type = "EF02";
            };
            ESP = {
              size = "1G";
              type = "EF00";
              content = {
                type = "mdraid";
                name = "boot";
              };
            };
            zfs = {
              size = "100%";
              content = {
                type = "zfs";
                pool = "zroot";
              };
            };
          };
        };
      };
      two = {
        type = "disk";
        device = "/dev/nvme1n1";
        content = {
          type = "gpt";
          partitions = {
            boot = {
              size = "1M";
              type = "EF02";
            };
            ESP = {
              size = "1G";
              type = "EF00";
              content = {
                type = "mdraid";
                name = "boot";
              };
            };
            zfs = {
              size = "100%";
              content = {
                type = "zfs";
                pool = "zroot";
              };
            };
          };
        };
      };
    };
    mdadm = {
      boot = {
        type = "mdadm";
        level = 1;
        metadata = "1.0";
        content = {
          type = "filesystem";
          format = "vfat";
          mountpoint = "/boot";
          mountOptions = [ "umask=0077" ];
        };
      };
    };
    zpool = {
      zroot = {
        type = "zpool";
        mode = "mirror";
        options.ashift = "12"; # Optimized for NVMe SSDs
        rootFsOptions = {
          compression = "zstd";
          acltype = "posixacl";
          xattr = "sa";
          atime = "off";
          "com.sun:auto-snapshot" = "true";
          mountpoint = "none";
        };

        datasets = {
          "root" = {
            type = "zfs_fs";
            options = {
              mountpoint = "none";
            };
          };
          "root/nixos" = {
            type = "zfs_fs";
            options.mountpoint = "/";
            mountpoint = "/";
          };
          "root/tmp" = {
            type = "zfs_fs";
            mountpoint = "/tmp";
            options = {
              mountpoint = "/tmp";
              sync = "disabled";
            };
          };
          "swap" = {
            type = "zfs_volume";
            size = "16G"; # Set swap size based on RAM
            options = {
              volblocksize = "4K"; # Optimized for swap
              "org.zfs:swap" = "on";
            };
            content = {
              type = "swap";
            };
          };
        };
      };
    };
  };
}
