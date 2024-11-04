{ inputs, ... }:
{
  imports = [ inputs.disko.nixosModules.disko ];

  disko.devices = {
    disk = {
      main = {
        device = "/dev/disk/by-diskseq/9";
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            esp = {
              priority = 1;
              name = "ESP";
              type = "EF00";
              start = "1M";
              end = "128M";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [ "umask=0077" ];
              };
            };
            root = {
              size = "100%";
              content = {
                type = "btrfs";
                extraArgs = [ "-f" ]; # Override existing partition
                # Subvolumes must set a mountpoint in order to be mounted,
                # unless their parent is mounted
                subvolumes = {
                  "@root" = {
                    mountpoint = "/";
                  };
                  "@nix" = {
                    mountOptions = [
                      "compress=zstd:1"
                      "noatime"
                      "noacl"
                    ];
                    mountpoint = "/nix";
                  };
                  "@persist" = {
                    mountOptions = [
                      "compress=zstd"
                      "noatime"
                    ];
                    mountpoint = "/persist";
                  };
                };
              };
            };
          };
        };
      };
    };
  };
}
