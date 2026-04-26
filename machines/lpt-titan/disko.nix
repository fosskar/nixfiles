{
  self,
  config,
  preservationDiskoPostMountHook,
  ...
}:
{
  imports = [
    self.modules.nixos.bcachefs
    self.modules.nixos.preservation
  ];

  clan.core.vars.generators.disk-encryption-password = {
    prompts.password = {
      type = "hidden";
      description = "bcachefs disk encryption password";
      persist = true;
    };
    files.password.neededFor = "partitioning";
  };

  preservation.rollback = {
    type = "bcachefs";
    subvolume = "@root";
  };

  disko.devices = {
    disk."main" = {
      type = "disk";
      device = "/dev/nvme0n1";
      content = {
        type = "gpt";
        partitions = {
          #"boot" = {
          #  size = "1M";
          #  type = "EF02"; # for grub MBR
          #  priority = 1;
          #};
          "ESP" = {
            type = "EF00";
            size = "1G";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
              mountOptions = [ "umask=0077" ];
            };
          };
          "root" = {
            size = "100%";
            content = {
              type = "bcachefs";
              filesystem = "main";
              label = "nixos";
              extraFormatArgs = [ "--discard" ];
            };
          };
        };
      };
    };
    bcachefs_filesystems = {
      "main" = {
        type = "bcachefs_filesystem";
        passwordFile = config.clan.core.vars.generators.disk-encryption-password.files.password.path;
        extraFormatArgs = [
          "--compression=lz4"
          "--background_compression=lz4"
        ];
        postMountHook = preservationDiskoPostMountHook;
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
