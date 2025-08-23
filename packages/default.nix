{ pkgs }:
let
  # get all .nix files in this directory except default.nix
  packageFiles = builtins.filter 
    (name: name != "default.nix" && pkgs.lib.hasSuffix ".nix" name)
    (builtins.attrNames (builtins.readDir ./.));
  
  # convert filename to package name (remove .nix suffix)
  packageName = file: pkgs.lib.removeSuffix ".nix" file;
  
  # create attribute set of all packages
  packages = builtins.listToAttrs (
    map (file: {
      name = packageName file;
      value = pkgs.callPackage (./. + "/${file}") { };
    }) packageFiles
  );
in
packages