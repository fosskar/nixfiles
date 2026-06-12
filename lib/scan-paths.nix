{ lib, ... }:
{
  scanPaths =
    path:
    {
      exclude ? [ ],
    }:
    let
      # files handled explicitly by their owners (machine configs, disko, hm
      # entrypoints, facter reports), never auto-imported
      alwaysExcluded = [
        "flake-module.nix"
        "configuration.nix"
        "disko.nix"
        "home.nix"
        "facter.json"
      ];
      allFiles = builtins.attrNames (
        lib.attrsets.filterAttrs (
          filename: _type:
          (!lib.any (excluded: filename == excluded) (exclude ++ alwaysExcluded))
          && (
            (_type == "directory") # include directories
            || (
              (filename != "default.nix") # ignore default.nix
              && (lib.strings.hasSuffix ".nix" filename) # include .nix files
            )
          )
        ) (builtins.readDir path)
      );
    in
    builtins.map (f: (path + "/${f}")) allFiles;
}
