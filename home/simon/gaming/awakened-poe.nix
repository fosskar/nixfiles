{
  lib,
  config,
  pkgs,
  ...
}:
with lib;

let
  cfg = config.module.gaming.awakened-poe;
in
{
  options = {
    module.gaming.awakened-poe.enable = mkEnableOption "Enables Awakened-POE-Trade";
  };

  config = mkIf cfg.enable {
    home.packages = [ (import ../../../packages/awakened-poe-trade.nix { inherit pkgs; }) ];
  };
}
