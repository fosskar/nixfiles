{ lib, ... }:

with lib;
{

  options = {
    module.desktop.wayland.bar = mkOption {
      type = types.enum [
        "hyprpanel"
        "ags"
      ];
      default = "hyprpanel";
      description = "Selects which bar to enable: either 'hyprpanel' or 'ags'";
    };
  };

  imports = [
    ./ags
    ./hyprpanel
  ];
}
