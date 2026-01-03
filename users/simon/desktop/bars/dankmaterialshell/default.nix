{
  config,
  lib,
  inputs,
  ...
}:
{
  imports = [
    inputs.dms.homeModules.niri
    inputs.dms.homeModules.default
  ];

  config = lib.mkIf (config.nixfiles.quickshell == "dms") {
    # symlink settings.json directly - force overwrites on each rebuild
    # (GUI changes won't persist - see github.com/AvengeMedia/DankMaterialShell/issues/1180)
    xdg.configFile."DankMaterialShell/settings.json" = {
      source = ./settings.json;
      force = true;
    };

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

      niri = {
        enableSpawn = false;
        includes = {
          override = false;
          filesToInclude = [
            "alttab"
            "layout"
            "wpblur"
          ];
        };
      };
    };
  };
}
