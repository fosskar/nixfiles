{
  config,
  pkgs,
  lib,
  ...
}:
{

  boot = {
    kernelPackages = pkgs.linuxPackages;

    # nixos-containers not needed in vms
    enableContainers = false;

    growPartition = true;

    loader = {
      timeout = lib.mkDefault 0;
      efi.canTouchEfiVariables = lib.mkDefault false;

      # vms typically use systemd-boot for simplicity
      systemd-boot = {
        enable = lib.mkDefault true;
        configurationLimit = lib.mkDefault 5;
      };

      grub = {
        enable = lib.mkDefault false;
        efiSupport = lib.mkDefault true;
        efiInstallAsRemovable = lib.mkDefault true;
      };
    };

    kernel.sysctl."vm.overcommit_memory" = lib.mkDefault "1";

    initrd = {
      verbose = false;
      # common disk/usb controller modules for cloud vms
      availableKernelModules = [
        "ahci"
        "xhci_pci"
        "sd_mod"
        "sr_mod"
      ];
      systemd = {
        suppressedUnits = lib.mkIf config.systemd.enableEmergencyMode [
          "emergency.service"
          "emergency.target"
        ];
      };
    };

    kernelParams = [
      # auto-reboot on panic
      "panic=1"
      "boot.panic_on_fail"

      # kernel page table isolation
      "pti=auto"

      # no logo needed in vms
      "logo.nologo"

      "nohibernate"
    ];
  };
}
