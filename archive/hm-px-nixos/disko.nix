# /etc/nixos/disko-raid.nix
{ inputs, ... }:
{
  imports = [ inputs.disko.nixosModules.disko ];

  boot.swraid.mdadmConf = ''
    MAILADDR root
  '';

  disko.devices = {
    disk = {
      sda = {
        type = "disk";
        device = "/dev/sda";
        content = {
          type = "gpt";
          partitions = {
            bios = {
              size = "1M";
              type = "EF02";
            };
            esp = {
              size = "1G";
              type = "EF00";
              content = {
                type = "mdraid";
                name = "md-boot";
              };
            };
            zfs = {
              size = "100%";
              content = {
                type = "zfs";
                pool = "tank";
              };
            };
          };
        };
      };

      nvme = {
        type = "disk";
        device = "/dev/nvme0n1";
        content = {
          type = "gpt";
          partitions = {
            bios = {
              size = "1M";
              type = "EF02";
            };
            esp = {
              size = "1G";
              type = "EF00";
              content = {
                type = "mdraid";
                name = "md-boot";
              };
            };
            zfs = {
              size = "100%";
              content = {
                type = "zfs";
                pool = "tank";
              };
            };
          };
        };
      };
    };

    mdadm = {
      "md-boot" = {
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
      tank = {
        type = "zpool";
        mode = "mirror";
        options.ashift = "12";
        rootFsOptions = {
          compression = "zstd";
          acltype = "posixacl";
          xattr = "sa";
          atime = "off";
          mountpoint = "none";
        };

        datasets = {
          "root" = {
            type = "zfs_fs";
            options.mountpoint = "none";
          };
          "root/nixos" = {
            type = "zfs_fs";
            mountpoint = "/";
            options.mountpoint = "/";
          };
          "root/home" = {
            type = "zfs_fs";
            mountpoint = "/home";
          };
          "swap" = {
            type = "zfs_volume";
            size = "8G";
            content.type = "swap";
          };
        };
      };
    };
  };
}
