{ pkgs, lib, ... }:
{
  boot = {
    tmp.cleanOnBoot = true;
    loader = {
      timeout = lib.mkDefault 1;
      generationsDir.copyKernels = true;
      systemd-boot = {
        enable = true;
        configurationLimit = 3;
      };
      efi.canTouchEfiVariables = true;
    };
    kernelPackages = pkgs.linuxPackages_latest; # pkgs.linuxPackages_xanmod_latest, pkgs.linuxPackages_zen, pkgs.linuxPackages_lqx, linuxPackages_latest
    kernelParams = [
      # disable displaying of the built-in Linux logo
      "logo.nologo"
      # disable usb autosuspend
      "usbcore.autosuspend=-1"
      "nohibernate"
      "nowatchdog"
      "modprobe.blacklist=sp5100_tco"
    ];
  };
}
