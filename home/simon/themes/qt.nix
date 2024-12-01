{
  lib,
  config,
  ...
}:

with lib;

let
  cfg = config.module.themes.qt;
in
{
  options.module.themes.qt = {
    enable = mkEnableOption "Enable qt";
  };

  config = mkIf cfg.enable {
    qt = {
      enable = true;
      platformTheme = {
        name = "gtk4";
      };
      style = {
        name = "adwaita-dark";
      };
    };
  };
}
