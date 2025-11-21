{
  mylib,
  pkgs,
  inputs,
  ...
}:
{
  imports = [
    #inputs.dms.homeModules.dankMaterialShell.niri
    inputs.dms.homeModules.dankMaterialShell.default
  ]
  ++ mylib.scanPaths ./. { };
  #xdg.configFile."DankMaterialShell/colors.json".source = ./colors.json;

  programs.dankMaterialShell = {
    enable = true;
    systemd = {
      enable = true;
      restartIfChanged = true;
    };
    enableSystemMonitoring = true;
    enableBrightnessControl = false;
    enableCalendarEvents = false;
    enableClipboard = true;
    enableVPN = true;
    enableColorPicker = false;
    enableDynamicTheming = true;
    enableAudioWavelength = true;
    enableSystemSound = true;

    default.settings = {
      theme = "dark";
      dynamicTheming = true;
    };

    #niri = {
    #  enableKeybinds = false;
    #  enableSpawn = false;
    #};
    quickshell.package = inputs.quickshell.packages.${pkgs.stdenv.hostPlatform.system}.default;
  };
}
