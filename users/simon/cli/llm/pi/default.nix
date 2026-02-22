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
  ];

  home.file = {
    ".pi/agent/AGENTS.md".source = ../AGENTS.md;
    ".pi/agent/settings.json".source = ./settings.json;
  }
  // extensionEntries
  // promptEntries;
}
