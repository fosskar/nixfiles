{
  config,
  pkgs,
  lib,
  ...
}:
with lib;

let
  cfg = config.module.browser.ladybird;
in
{
  options = {
    module.browser.ladybird.enable = mkEnableOption "the Ladybird web browser";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      ladybird
    ];
  };
}
