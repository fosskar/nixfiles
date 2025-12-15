{ mylib, lib, ... }:
{
  imports = [
    ../../modules/power
  ]
  ++ (mylib.scanPaths ./. { exclude = [ ]; });

  nixpkgs.hostPlatform = "x86_64-linux";

  nixfiles = {
    power.tuned = {
      enable = true;
      profile = [
        "virtual-guest"
        "network-latency"
      ];
    };
  };

  services.qemuGuest.enable = true;

  # vm specific
  hardware = {
    firmware = lib.mkForce [ ];
    enableRedistributableFirmware = lib.mkForce false;
  };

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
