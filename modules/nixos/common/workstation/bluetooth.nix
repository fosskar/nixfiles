{
  flake.modules.nixos.workstation =
    { lib, pkgs, ... }:
    {
      hardware.bluetooth = {
        enable = lib.mkDefault true;
        package = pkgs.bluez5-experimental;
        #powerOnBoot = lib.mkDefault false;
        settings.General = {
          JustWorksRepairing = "always";
          Experimental = true;
        };
      };
    };
}
