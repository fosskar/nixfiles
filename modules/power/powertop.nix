{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.nixfiles.power.powertop;
in
{
  config = lib.mkIf cfg.enable {
    powerManagement.powertop.enable = true;
    environment.systemPackages = [ pkgs.powertop ];
  };
}
