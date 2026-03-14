{
  mylib,
  inputs,
  pkgs,
  lib,
  ...
}:
let
  extensionFiles = builtins.readDir ./extensions;
  extensionEntries = lib.mapAttrs' (
    name: _: lib.nameValuePair ".pi/agent/extensions/${name}" { source = ./extensions/${name}; }
  ) extensionFiles;
  promptFiles = builtins.readDir ./prompts;
  promptEntries = lib.mapAttrs' (
    name: _: lib.nameValuePair ".pi/agent/prompts/${name}" { source = ./prompts/${name}; }
  ) promptFiles;

  # declarative pi settings — source of truth in nixfiles.
  # merged on top of existing local settings.json (or deployed 1:1 if none exists).
  piSettings = {
    lastChangelogVersion = "99.99.99";
    #defaultProvider = "anthropic";
    #defaultModel = "claude-opus-4-6";
    #defaultThinkingLevel = "low";
    hideThinkingBlock = true;
    steeringMode = "all";
    followUpMode = "all";
    theme = "dark";
    quietStartup = true;
    packages = [
      {
        source = "git:github.com/fosskar/pi-pack";
      }
      {
        source = "git:github.com/rytswd/pi-agent-extensions";
        extensions = [
          "direnv/index.ts"
          "fetch/index.ts"
          "questionnaire/index.ts"
          "slow-mode/index.ts"
        ];
      }
      {
        source = "git:github.com/rytswd/pi-agent-extensions";
        extensions = [
          "direnv/index.ts"
          "fetch/index.ts"
          "questionnaire/index.ts"
          "slow-mode/index.ts"
        ];
      }
      {
        source = "git:github.com/tmustier/pi-extensions";
        extensions = [
          "files-widget/index.ts"
          "tab-status/tab-status.ts"
          "ralph-wiggum/index.ts"
          "agent-guidance/agent-guidance.ts"
        ];
      }
      {
        source = "git:github.com/hjanuschka/shitty-extensions";
        extensions = [
          "extensions/clipboard.ts"
          "extensions/oracle.ts"
          "extensions/memory-mode.ts"
        ];
      }
      {
        source = "npm:pi-powerline-footer";
      }
    ];
    compaction.enabled = true;
  };
  piSettingsFile = pkgs.writeText "pi-settings-overlay.json" (builtins.toJSON piSettings);
in
{
  imports = mylib.scanPaths ./. {
    exclude = [
      "extensions"
      "prompts"
    ];
  };

  home.packages = [
    inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.pi
    pkgs.glow
  ];

  home.file = {
    ".pi/agent/AGENTS.md".source = ../AGENTS.md;

  }
  // extensionEntries
  // promptEntries;

  # deploy or merge pi settings.json
  home.activation.piSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    settings="$HOME/.pi/agent/settings.json"
    mkdir -p "$(dirname "$settings")"
    # migration: replace old nix symlink with real file
    if [ -L "$settings" ]; then
      existing=$(cat "$settings" 2>/dev/null || echo '{}')
      rm "$settings"
      echo "$existing" > "$settings"
    fi
    if [ -f "$settings" ]; then
      # merge: nix keys win, local-only keys preserved
      ${pkgs.jq}/bin/jq -s '.[0] * .[1]' "$settings" "${piSettingsFile}" > "$settings.tmp"
      mv "$settings.tmp" "$settings"
    else
      # no existing file: deploy 1:1
      cp "${piSettingsFile}" "$settings"
      chmod 644 "$settings"
    fi
  '';
}
