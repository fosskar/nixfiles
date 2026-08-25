{
  flake.modules.nixos.base =
    { lib, ... }:
    {
      # initrd.systemd.enable is the nixpkgs default since 26.05; bootloader chosen per machine (grub/systemdBoot/lanzaboote)

      boot = {
        initrd.availableKernelModules = [
          "ahci"
          "xhci_pci"
          "sd_mod"
          "sr_mod"
        ];

        kernelParams = [ "logo.nologo" ];

        # nix >=2.30 builds in /nix/var/nix/builds, not /tmp, so tmpfs is safe on builders
        tmp.useTmpfs = lib.mkDefault true;

        loader = {
          timeout = lib.mkDefault 5;
          generationsDir.copyKernels = true;
        };
      };
    };
}
