{ config, lib, ... }:
{
  boot = {
    initrd = {
      systemd.enable = lib.mkDefault (!config.boot.swraid.enable && !config.boot.isContainer);
      availableKernelModules = [
        "ahci"
        "xhci_pci"
        "sd_mod"
        "sr_mod"
      ];
    };

    kernelParams = [ "logo.nologo" ];

    loader = {
      timeout = lib.mkDefault 0;
      generationsDir.copyKernels = true;
      grub = {
        enable = lib.mkDefault false;
        copyKernels = lib.mkDefault true; # required when /boot is on separate partition from /
        efiSupport = lib.mkDefault true;
        efiInstallAsRemovable = lib.mkDefault true;
        splashImage = null; # disable splash
        memtest86.enable = lib.mkDefault false;
      };
      systemd-boot = {
        enable = lib.mkDefault true;
        editor = lib.mkDefault false;
        configurationLimit = lib.mkDefault 15;
      };
    };

    tmp.cleanOnBoot = lib.mkDefault true;
  };
}
