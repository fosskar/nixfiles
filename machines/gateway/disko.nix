{
  self,
  preservationDiskoPostMountHook,
  ...
}:
{
  imports = [
    self.modules.nixos.btrfs
    self.modules.nixos.preservation
  ];

  preservation.rollback = {
    type = "btrfs";
    deviceLabel = "root";
  };

  disko.devices = {
    disk."main" = {
      type = "disk";
      device = "/dev/sda";
      content = {
        type = "gpt";
        partitions = {
          "boot" = {
            size = "1M";
            type = "EF02";
            priority = 1;
          };
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
            label = "root";
            content = {
              type = "btrfs";
              extraArgs = [
                "--force"
                "--label root"
              ];
              postMountHook = preservationDiskoPostMountHook;
              subvolumes = {
                "@root" = {
                  mountpoint = "/";
                  mountOptions = [
                    "compress=zstd"
                    "noatime"
                  ];
                };
                "@nix" = {
                  mountpoint = "/nix";
                  mountOptions = [
                    "compress=zstd"
                    "noatime"
                  ];
                };
                "@persist" = {
                  mountpoint = "/persist";
                  mountOptions = [
                    "compress=zstd"
                    "noatime"
                  ];
                };
              };
            };
          };
        };
      };
    };
  };
}
