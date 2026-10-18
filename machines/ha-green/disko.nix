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

  preservation.rollback.deviceLabel = "root";

  # ~95 MB of kernel and initrd per generation; the default of 20 does not fit /boot
  boot.loader.generic-extlinux-compatible.configurationLimit = 5;

  disko.devices = {
    disk."main" = {
      type = "disk";
      # emmc; the dtb aliases mmc0 to sdhci, the sd card is mmcblk1
      device = "/dev/mmcblk0";
      content = {
        type = "gpt";
        partitions = {
          # haos's u-boot lives in the first 16 MiB (spl.img, u-boot at 32 KiB)
          "boot" = {
            start = "16M";
            size = "1G";
            label = "boot";
            # u-boot reads extlinux/extlinux.conf from fat or ext4, not btrfs
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
                  mountOptions = [ "compress=zstd" ];
                };
                "@nix" = {
                  mountpoint = "/nix";
                  mountOptions = [ "compress=zstd" ];
                };
                "@persist" = {
                  mountpoint = "/persist";
                  mountOptions = [ "compress=zstd" ];
                };
              };
            };
          };
        };
      };
    };
  };
}
