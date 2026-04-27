{
  flake.modules.nixos.base =
    { lib, ... }:
    {
      # srvos sets: initrd.systemd.enable, tmp.cleanOnBoot
      # bootloader is not chosen here: each machine imports either
      # self.modules.nixos.grub, self.modules.nixos.systemdBoot, or
      # self.modules.nixos.lanzaboote.

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
