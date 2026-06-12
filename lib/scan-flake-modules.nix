{ lib, ... }:
{
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
    map (dir: basePath + "/${dir}/flake-module.nix") flakeModules;
}
