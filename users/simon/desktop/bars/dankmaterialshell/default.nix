{
  config,
  lib,
  inputs,
  pkgs,
  ...
}:
let
  t = config.theme;
  dmsTheme = {
    dark = {
      inherit (t) primary;
      primaryText = "#FFFFFF";
      primaryContainer = t.primaryDark;
      inherit (t) secondary;
      surfaceTint = t.primary;
      surface = t.bg;
      surfaceText = t.fg;
      surfaceVariant = t.bgLightest;
      surfaceVariantText = t.fgMuted;
      surfaceContainer = t.bgLight;
      surfaceContainerHigh = t.bgLighter;
      surfaceContainerHighest = t.bgLightest;
      background = t.bg;
      backgroundText = t.fg;
      outline = t.fgDim;
      inherit (t) error;
      inherit (t) warning;
      inherit (t) info;
    };
    light = {
      inherit (t.light) primary;
      primaryText = "#FFFFFF";
      inherit (t.light) primaryContainer;
      secondary = t.primary;
      surfaceTint = t.primary;
      surface = t.light.bg;
      surfaceText = t.light.fg;
      surfaceVariant = "#ECEFF1";
      surfaceVariantText = t.light.fgMuted;
      surfaceContainer = t.light.bgDark;
      surfaceContainerHigh = t.light.bgDarker;
      surfaceContainerHighest = t.light.bgDarkest;
      background = t.light.bg;
      backgroundText = t.light.fg;
      inherit (t.light) outline;
      inherit (t.light) error;
      inherit (t.light) warning;
      info = t.primary;
    };
  };
  themeJson = pkgs.writeText "grey-teal.json" (builtins.toJSON dmsTheme);
in
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
    xdg.configFile."DankMaterialShell/themes/grey-teal.json".source = themeJson;

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
        };
      };
    };
  };
}
