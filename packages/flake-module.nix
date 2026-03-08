{ inputs, ... }:
let
  inherit (inputs.nixpkgs) lib;
  mylib = import ../lib { inherit lib; };
in
{
  perSystem =
    { system, ... }:
    {
      packages =
        let
          pkgs = import inputs.nixpkgs { inherit system; };

          # auto-discover all package directories
          packageDirs = mylib.scanPaths ./. {
            exclude = [ ];
          };

          # extra args to pass to specific packages
          extraArgs = {
            stirling-pdf = {
              isDesktopVariant = false;
            };
          };

          # convert to attrset of callPackage calls
          packagesAttrset = lib.listToAttrs (
            map (path: {
              name = baseNameOf path;
              value = pkgs.callPackage path (extraArgs.${baseNameOf path} or { });
            }) packageDirs
          );
        in
        packagesAttrset;
    };
}
