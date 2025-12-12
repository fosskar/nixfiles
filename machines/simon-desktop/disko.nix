# Disko configuration for NVMe disk with BTRFS impermanence
# Based on https://www.notashelf.dev/posts/impermanence
_: {
  disko.devices = {
    disk = {
      main = {
        type = "disk";
        device = "/dev/nvme0n1"; # Adjust this to your actual NVMe device
        content = {
          type = "gpt";
          partitions = {
            # Boot partition - 1GB like in the example
            ESP = {
              label = "boot";
              size = "1G";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [
                  "defaults"
                  "umask=0027"
                ];
              };
            };
            # Main BTRFS partition (no encryption)
            root = {
              size = "100%";
              content = {
                type = "btrfs";
                extraArgs = [
                  "-L"
                  "nixos"
                  "-f"
                ];
                subvolumes = {
                  # Root subvolume (will be rolled back on each boot)
                  "@root" = {
                    mountpoint = "/";
                    mountOptions = [
                      "compress=zstd"
                      "noatime"
                    ];
                  };
                  # Home subvolume
                  "@home" = {
                    mountpoint = "/home";
                    mountOptions = [
                      "compress=zstd"
                      "noatime"
                    ];
                  };
                  # Nix store subvolume
                  "@nix" = {
                    mountpoint = "/nix";
                    mountOptions = [
                      "compress=zstd"
                      "noatime"
                    ];
                  };
                  # Persistent data subvolume
                  "@persist" = {
                    mountpoint = "/persist";
                    mountOptions = [
                      "compress=zstd"
                      "noatime"
                    ];
                  };
                  # Sops-nix age key subvolume (separate from impermanence)
                  # See: https://git.clan.lol/clan/clan-core/issues/3590
                  "@sops-nix" = {
                    mountpoint = "/var/lib/sops-nix";
                    mountOptions = [
                      "compress=zstd"
                      "noatime"
                    ];
                  };
                  # Log subvolume
                  "@log" = {
                    mountpoint = "/var/log";
                    mountOptions = [
                      "compress=zstd"
                      "noatime"
                    ];
                  };
                  "@swap" = {
                    mountpoint = "/swap";
                    swap.swapfile.size = "16G";
                  };
                };
              };
            };
          };
        };
      };
    };
  };
  fileSystems = {
    "/persist".neededForBoot = true;
    "/nix".neededForBoot = true;
    "/home".neededForBoot = true;
    "/var/lib/sops-nix".neededForBoot = true;
  };
}
