{
  lib,
  config,
  inputs,
  pkgs,
  ...
}:
with lib;

let
  cfg = config.module.browser.zen-browser;
in
{
  options = {
    module.browser.zen-browser.enable = mkEnableOption "Enables zen-browser";
  };

  config = mkIf cfg.enable {
    home.packages = [
      inputs.zen-browser.packages.${pkgs.system}.default
    ];
  };
}
