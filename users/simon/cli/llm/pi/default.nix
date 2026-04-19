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
  skillDirs = builtins.readDir ./skills;
  skillEntries = lib.mapAttrs' (
    name: _: lib.nameValuePair ".pi/agent/skills/${name}" { source = ./skills/${name}; }
  ) (lib.filterAttrs (_: type: type == "directory") skillDirs);

  # declarative pi settings — source of truth in nixfiles.
  # merged on top of existing local settings.json (or deployed 1:1 if none exists).
  piSettings = {
    lastChangelogVersion = "99.99.99";
    #defaultProvider = "anthropic";
    #defaultModel = "claude-opus-4-6";
    #defaultThinkingLevel = "low";
    hideThinkingBlock = true;
    followUpMode = "all";
    theme = "dark";
    quietStartup = true;
    skills = [ "~/.claude/skills" ];
    packages = [
      {
        source = "git:github.com/rytswd/pi-agent-extensions";
      }
      #{
      #  source = "git:github.com/nicobailon/pi-powerline-footer";
      #}
    ];
    compaction.enabled = true;
  };
  piSettingsFile = pkgs.writeText "pi-settings-overlay.json" (builtins.toJSON piSettings);

  piModels = {
    providers = {
      local = {
        baseUrl = "http://localhost:1234/v1";
        api = "openai-completions";
        apiKey = "local";
        models = [
          { id = "google/gemma-4-26b-a4b"; }
        ];
      };
    };
  };
  piModelsFile = pkgs.writeText "pi-models.json" (builtins.toJSON piModels);
in
{
  imports = mylib.scanPaths ./. {
    exclude = [
      "extensions"
      "prompts"
      "skills"
    ];
  };

  home.packages = [
    inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.pi
  ];

  home.file = {
    ".pi/agent/AGENTS.md".source = ../AGENTS.md;
    ".pi/agent/models.json".source = piModelsFile;

  }
  // extensionEntries
  // promptEntries
  // skillEntries;

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
