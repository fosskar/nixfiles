_: {
  flake.modules.homeManager.llm =
    {
      self,
      pkgs,
      ...
    }:
    let
      t = self.themes.${self.theme};
      vars = {
        primary = t.dark.accent.primary;
        primaryDark = t.dark.bg.overlay;
        secondary = t.ansi.normal.cyan;
        terminalDefault = "";
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
        selectedBg = "terminalDefault";
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
      piTheme = {
        "$schema" =
          "https://raw.githubusercontent.com/earendil-works/pi-mono/main/packages/coding-agent/src/modes/interactive/theme/theme-schema.json";
        name = "custom";
        inherit vars colors export;
      };
      # omp extends the pi token set: statusLine segments + pythonMode
      ompTheme = {
        name = "custom";
        inherit vars export;
        colors = colors // {
          pythonMode = "magenta";
          statusLineBg = "terminalDefault";
          statusLineSep = "fgDim";
          statusLineModel = "magenta";
          statusLinePath = "blue";
          statusLineGitClean = "green";
          statusLineGitDirty = "warning";
          statusLineContext = "secondary";
          statusLineSpend = "secondary";
          statusLineStaged = "green";
          statusLineDirty = "warning";
          statusLineUntracked = "error";
          statusLineOutput = "fg";
          statusLineCost = "warning";
          statusLineSubagents = "magenta";
        };
      };
    in
    {
      home.file.".pi/agent/themes/custom.json".source = pkgs.writeText "pi-theme-custom.json" (
        builtins.toJSON piTheme
      );
      home.file.".omp/agent/themes/custom.json".source = pkgs.writeText "omp-theme-custom.json" (
        builtins.toJSON ompTheme
      );
    };
}
