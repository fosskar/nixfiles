{
  pkgs,
  inputs,
  ...
}:
{
  imports = [
    inputs.dankmaterialshell.homeModules.dankMaterialShell
  ];

  #xdg.configFile."DankMaterialShell/colors.json".source = ./colors.json;

  programs.dankMaterialShell = {
    enable = true;
    enableKeybinds = false;
    enableSystemd = true;
    enableSpawn = false;
    enableBrightnessControl = false;
    enableNightMode = false;
    enableCalendarEvents = false;
    quickshell.package = inputs.quickshell.packages.${pkgs.system}.default;
  };
}
