{ lib, ... }:

with lib;
{

  options = {
    module.desktop.wayland.applauncher = mkOption {
      type = types.enum [
        "anyrun"
      ];
      default = "anyrun";
      description = "Selects which applauncher to use.";
    };
  };

  imports = [
    ./anyrun
  ];
}
