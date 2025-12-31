{ lib, ... }:
{
  hardware.bluetooth = {
    enable = lib.mkDefault true;
    powerOnBoot = lib.mkDefault false;
    settings.General.Experimental = lib.mkDefault true;
  };
}
