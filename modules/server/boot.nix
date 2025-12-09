{ config, lib, ... }:
{
  boot = {
    # nixos-containers not needed on servers
    enableContainers = false;

    # auto-expand partition (useful for VMs, harmless on bare-metal)
    growPartition = true;

    tmp.cleanOnBoot = lib.mkDefault true;

    loader = {
      timeout = lib.mkDefault 0;
      efi.canTouchEfiVariables = lib.mkDefault false;
      generationsDir.copyKernels = true;

      systemd-boot = {
        enable = lib.mkDefault true;
        configurationLimit = lib.mkDefault 5;
      };

      grub = {
        enable = lib.mkDefault false;
        configurationLimit = lib.mkDefault 5;
        efiSupport = lib.mkDefault true;
        efiInstallAsRemovable = lib.mkDefault true;
        splashImage = lib.mkDefault null;
        memtest86.enable = lib.mkDefault false;
      };
    };

    # memory overcommit helps low-memory environments
    kernel.sysctl."vm.overcommit_memory" = lib.mkDefault "1";

    initrd = {
      verbose = false;
      # common disk/usb controller modules
      availableKernelModules = [
        "ahci"
        "xhci_pci"
        "sd_mod"
        "sr_mod"
      ];
      systemd.suppressedUnits = lib.mkIf config.systemd.enableEmergencyMode [
        "emergency.service"
        "emergency.target"
      ];
    };

    kernelParams = [
      # auto-reboot on panic (headless servers)
      "panic=1"
      "boot.panic_on_fail"

      # kernel page table isolation
      "pti=auto"

      # no boot logo
      "logo.nologo"

      # disable hibernation (security)
      "nohibernate"
    ];
  };
}
