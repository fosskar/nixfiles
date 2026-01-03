{
  config,
  lib,
  mylib,
  inputs,
  ...
}:
{
  imports = [
    inputs.dms.homeModules.niri
    inputs.dms.homeModules.default
  ]
  ++ mylib.scanPaths ./. { };

  config = lib.mkIf (config.nixfiles.desktop.shell == "dms") {
    #xdg.configFile."DankMaterialShell/colors.json".source = ./colors.json;

    programs.dank-material-shell = {
      enable = true;
      systemd = {
        enable = true;
        restartIfChanged = true;
      };
      enableSystemMonitoring = true;
      enableCalendarEvents = false;
      enableVPN = true;
      enableDynamicTheming = true;
      enableAudioWavelength = true;

      default.settings = {
        theme = "dark";
        dynamicTheming = true;
      };

      niri = {
        #  enableKeybinds = false;
        enableSpawn = false;
        includes = {
          override = false;
          filesToInclude = [ ];
        };
      };

      #quickshell.package = inputs.quickshell.packages.${pkgs.stdenv.hostPlatform.system}.default;
    };
  };
}
