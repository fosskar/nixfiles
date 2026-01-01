{ config, ... }:
{
  # bcachefs disk encryption password
  # prompts during `clan vars generate`, deploys to /run/partitioning-secrets/ during install
  clan.core.vars.generators.disk-encryption-password = {
    prompts.password = {
      type = "hidden";
      description = "bcachefs disk encryption password";
      persist = true;
    };
    files.password.neededFor = "partitioning";
  };

  disko.devices = {
    disk = {
      main = {
        type = "disk";
        device = "/dev/nvme0n1";
        content = {
          type = "gpt";
          partitions = {
            ESP = {
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
            root = {
              size = "100%";
              content = {
                type = "bcachefs";
                filesystem = "main";
                label = "root";
                extraFormatArgs = [ "--discard" ];
              };
            };
          };
        };
      };
    };
    bcachefs_filesystems = {
      main = {
        type = "bcachefs_filesystem";
        passwordFile = config.clan.core.vars.generators.disk-encryption-password.files.password.path;
        extraFormatArgs = [
          "--compression=lz4"
          "--background_compression=lz4"
        ];
        subvolumes = {
          "@root" = {
            mountpoint = "/";
            mountOptions = [ "noatime" ];
          };
          "@home" = {
            mountpoint = "/home";
            mountOptions = [ "noatime" ];
          };
          "@nix" = {
            mountpoint = "/nix";
            mountOptions = [ "noatime" ];
          };
          "@persist" = {
            mountpoint = "/persist";
            mountOptions = [ "noatime" ];
          };
        };
      };
    };
  };
}
