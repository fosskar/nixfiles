{
  flake.modules.nixos.upower =
    { lib, ... }:
    {
      services.upower = {
        enable = true;
        # the default HybridSleep needs hibernation, which base disables via
        # security.protectKernelImage (nohibernate); upower then falls back anyway
        criticalPowerAction = lib.mkDefault "PowerOff";
      };
    };
}
