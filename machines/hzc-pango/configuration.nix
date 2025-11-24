{ lib, mylib, ... }:
{
  imports = [
    ../../modules/vm
    ../../modules/impermanence
    ../../modules/shared
  ]
  ++ (mylib.scanPaths ./. { });

  nixpkgs.hostPlatform = "x86_64-linux";

  # hetzner cloud uses legacy BIOS - use GRUB for hybrid boot
  boot.loader = {
    systemd-boot.enable = lib.mkForce false;
    grub = {
      enable = lib.mkForce true;
      device = "/dev/sda";
    };
  };
}
