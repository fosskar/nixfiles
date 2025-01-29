{
  self,
  lib,
  ...
}:

let
  overlaysPath = "${self}/overlays/nixpkgs";
  modules = builtins.filter lib.pathIsDirectory (
    map (module: "${overlaysPath}/${module}") (builtins.attrNames (builtins.readDir overlaysPath))
  );
in
{
  # Read all directories from overlaysPath
  imports = modules;
}
