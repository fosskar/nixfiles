{ config, pkgs, ... }:
let
  t = config.theme;
  piTheme = {
    "$schema" =
      "https://raw.githubusercontent.com/badlogic/pi-mono/main/packages/coding-agent/src/modes/interactive/theme/theme-schema.json";
    name = "custom";
    vars = {
      inherit (t) primary;
      inherit (t) primaryDark;
      inherit (t) secondary;
      inherit (t) bg;
      inherit (t) bgLight;
      inherit (t) bgLighter;
      inherit (t) bgLightest;
      inherit (t) fg;
      inherit (t) fgMuted;
      inherit (t) fgDim;
      inherit (t) error;
      inherit (t) warning;
      inherit (t.term) green;
      inherit (t.term) blue;
      inherit (t.term) magenta;
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
      toolPendingBg = "bgLight";
      toolSuccessBg = "bgLight";
      toolErrorBg = "bgLight";
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
      pageBg = t.bg;
      cardBg = t.bgLight;
      infoBg = t.bgLighter;
    };
  };
  piThemeFile = pkgs.writeText "pi-theme-custom.json" (builtins.toJSON piTheme);
in
{
  home.file.".pi/agent/themes/custom.json".source = piThemeFile;
}
