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
          && (filename != "flake-module.nix") # always ignore flake-module.nix
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

  # auto-discover flake-module.nix files in subdirectories
  scanFlakeModules =
    basePath:
    let
      dirs = builtins.readDir basePath;
      flakeModules = lib.filter (
        name:
        let
          type = dirs.${name};
          hasFlakeModule = builtins.pathExists (basePath + "/${name}/flake-module.nix");
        in
        type == "directory" && hasFlakeModule
      ) (builtins.attrNames dirs);
    in
    builtins.map (dir: basePath + "/${dir}/flake-module.nix") flakeModules;
}
