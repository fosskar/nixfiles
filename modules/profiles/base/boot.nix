{ lib, ... }:
{
  # srvos sets: initrd.systemd.enable, tmp.cleanOnBoot

  boot = {
    initrd.availableKernelModules = [
      "ahci"
      "xhci_pci"
      "sd_mod"
      "sr_mod"
    ];

    kernelParams = [ "logo.nologo" ];

    loader = {
      timeout = lib.mkDefault 0;
      generationsDir.copyKernels = true;
      grub = {
        enable = lib.mkDefault false;
        copyKernels = lib.mkDefault true;
        efiSupport = lib.mkDefault true;
        efiInstallAsRemovable = lib.mkDefault true;
        splashImage = null;
        memtest86.enable = lib.mkDefault false;
      };
      systemd-boot = {
        enable = lib.mkDefault true;
        editor = lib.mkDefault false;
        configurationLimit = lib.mkDefault 15;
      };
    };
  };
}
