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
in
{
  imports = mylib.scanPaths ./. {
    exclude = [ "extensions" ];
  };

  home.packages = [
    inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.pi
  ];

  home.file = {
    ".pi/agent/AGENTS.md".source = ../AGENTS.md;
    ".pi/agent/settings.json".source = ./settings.json;
  }
  // extensionEntries;
}
