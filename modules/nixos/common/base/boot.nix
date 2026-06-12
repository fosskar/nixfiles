{
  flake.modules.nixos.base =
    { lib, ... }:
    {
      # srvos sets initrd.systemd.enable + tmp.cleanOnBoot; bootloader chosen per machine (grub/systemdBoot/lanzaboote)

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
        };
      };
    };
}
