{
  config,
  inputs,
  pkgs,
  ...
}:
let
  t = config.theme;
  dmsTheme = {
    dark = {
      primary = t.dark.accent.primary;
      primaryText = "#FFFFFF";
      primaryContainer = t.dark.bg.overlay;
      secondary = t.ansi.normal.cyan;
      surfaceTint = t.dark.accent.primary;
      surface = t.dark.bg.base;
      surfaceText = t.dark.fg.base;
      surfaceVariant = t.dark.bg.overlay;
      surfaceVariantText = t.dark.fg.muted;
      surfaceContainer = t.dark.bg.surface;
      surfaceContainerHigh = t.dark.bg.elevated;
      surfaceContainerHighest = t.dark.bg.overlay;
      background = t.dark.bg.base;
      backgroundText = t.dark.fg.base;
      outline = t.dark.fg.dim;
      error = t.dark.semantic.error;
      warning = t.dark.semantic.warning;
      info = t.dark.semantic.info;
    };
    light = {
      primary = t.light.accent.primary;
      primaryText = "#FFFFFF";
      primaryContainer = t.light.bg.overlay;
      secondary = t.light.accent.secondary;
      surfaceTint = t.light.accent.primary;
      surface = t.light.bg.base;
      surfaceText = t.light.fg.base;
      surfaceVariant = "#ECEFF1";
      surfaceVariantText = t.light.fg.muted;
      surfaceContainer = t.light.bg.surface;
      surfaceContainerHigh = t.light.bg.elevated;
      surfaceContainerHighest = t.light.bg.overlay;
      background = t.light.bg.base;
      backgroundText = t.light.fg.base;
      outline = t.light.fg.dim;
      error = t.light.semantic.error;
      warning = t.light.semantic.warning;
      info = t.dark.accent.primary;
    };
  };
  themeJson = pkgs.writeText "grey-teal.json" (builtins.toJSON dmsTheme);
in
{
  imports = [
    inputs.dms.homeModules.niri
    inputs.dms.homeModules.default
  ];

  config = {
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
