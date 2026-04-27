{
  flake.modules.nixos.grub =
    { lib, ... }:
    {
      boot.loader.grub = {
        enable = true;
        copyKernels = lib.mkDefault true;
        efiSupport = lib.mkDefault true;
        efiInstallAsRemovable = lib.mkDefault true;
        splashImage = null;
        memtest86.enable = lib.mkDefault false;
      };
    };
}
