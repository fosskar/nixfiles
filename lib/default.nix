{ lib, ... }:
{
  scanPaths =
    path:
    {
      exclude ? [ ],
    }:
    let
      allFiles = builtins.attrNames (
        lib.attrsets.filterAttrs (
          filename: _type:
          (!lib.any (excluded: filename == excluded) exclude) # exclude files/directories in exclude list
          && (filename != "flake-part.nix") # always ignore flake-part.nix
          && (filename != "configuration.nix") # always ignore configuration.nix
          && (filename != "disko.nix") # always ignore configuration.nix
          && (filename != "home.nix") # always ignore configuration.nix
          && (filename != "facter.json") # always ignore configuration.nix
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

  # auto-discover flake-part.nix files in subdirectories
  scanFlakeParts =
    basePath:
    let
      dirs = builtins.readDir basePath;
      flakeParts = lib.filter (
        name:
        let
          type = dirs.${name};
          hasFlakePart = builtins.pathExists (basePath + "/${name}/flake-part.nix");
        in
        type == "directory" && hasFlakePart
      ) (builtins.attrNames dirs);
    in
    builtins.map (dir: basePath + "/${dir}/flake-part.nix") flakeParts;
}
