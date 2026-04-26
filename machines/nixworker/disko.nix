_: {
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
            label = "boot";
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
              };
            };
          };
        };
      };
    };
  };
}
