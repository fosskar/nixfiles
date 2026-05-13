{ config, pkgs, ... }:
let
  t = config.theme;
  piTheme = {
    "$schema" =
      "https://raw.githubusercontent.com/badlogic/pi-mono/main/packages/coding-agent/src/modes/interactive/theme/theme-schema.json";
    name = "custom";
    vars = {
      primary = t.dark.accent.primary;
      primaryDark = t.dark.bg.overlay;
      secondary = t.ansi.normal.cyan;
      bg = t.dark.bg.base;
      bgLight = t.dark.bg.surface;
      bgLighter = t.dark.bg.elevated;
      bgLightest = t.dark.bg.overlay;
      fg = t.dark.fg.base;
      fgMuted = t.dark.fg.muted;
      fgDim = t.dark.fg.dim;
      error = t.dark.semantic.error;
      warning = t.dark.semantic.warning;
      green = t.ansi.normal.green;
      blue = t.ansi.normal.blue;
      magenta = t.ansi.normal.magenta;
      toolPendingSurface = "#2A2618";
      toolSuccessSurface = "#1B2A20";
      toolErrorSurface = "#2A1B1B";
    };
    colors = {
      # core ui
      accent = "primary";
      border = "fgDim";
      borderAccent = "primary";
      borderMuted = "bgLightest";
      success = "green";
      error = "error";
      warning = "warning";
      muted = "fgMuted";
      dim = "fgDim";
      text = "";
      thinkingText = "fgMuted";

      # backgrounds & content
      selectedBg = "bgLightest";
      userMessageBg = "bgLightest";
      userMessageText = "fg";
      customMessageBg = "bgLighter";
      customMessageText = "";
      customMessageLabel = "secondary";
      toolPendingBg = "toolPendingSurface";
      toolSuccessBg = "toolSuccessSurface";
      toolErrorBg = "toolErrorSurface";
      toolTitle = "primary";
      toolOutput = "fg";

      # markdown
      mdHeading = "secondary";
      mdLink = "blue";
      mdLinkUrl = "fgMuted";
      mdCode = "secondary";
      mdCodeBlock = "fg";
      mdCodeBlockBorder = "fgDim";
      mdQuote = "fgMuted";
      mdQuoteBorder = "primary";
      mdHr = "fgDim";
      mdListBullet = "primary";

      # diffs
      toolDiffAdded = "green";
      toolDiffRemoved = "error";
      toolDiffContext = "fgMuted";

      # syntax
      syntaxComment = "fgDim";
      syntaxKeyword = "magenta";
      syntaxFunction = "blue";
      syntaxVariable = "fg";
      syntaxString = "green";
      syntaxNumber = "warning";
      syntaxType = "secondary";
      syntaxOperator = "fgMuted";
      syntaxPunctuation = "fgMuted";

      # thinking level borders (subtle → prominent)
      thinkingOff = "fgDim";
      thinkingMinimal = "fgMuted";
      thinkingLow = "secondary";
      thinkingMedium = "primary";
      thinkingHigh = "blue";
      thinkingXhigh = "magenta";

      # bash mode
      bashMode = "warning";
    };
    export = {
      pageBg = t.dark.bg.base;
      cardBg = t.dark.bg.surface;
      infoBg = t.dark.bg.elevated;
    };
  };
  piThemeFile = pkgs.writeText "pi-theme-custom.json" (builtins.toJSON piTheme);
in
{
  home.file.".pi/agent/themes/custom.json".source = piThemeFile;
}
