{ mylib, ... }:
{
  imports = mylib.scanPaths ./. { };

  nixpkgs.hostPlatform = "x86_64-linux";

  # hetzner cloud uses legacy BIOS - use GRUB for hybrid boot
  boot = {
    loader = {
      systemd-boot.enable = false;
      grub = {
        enable = true;
        device = "/dev/sda";
      };
    };
    supportedFilesystems = [ "btrfs" ];
    initrd = {
      supportedFilesystems = [ "btrfs" ];
      # no console access - emergency mode would just hang
      systemd.suppressedUnits = [
        "emergency.service"
        "emergency.target"
      ];
    };
  };
}
