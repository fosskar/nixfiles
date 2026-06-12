{ inputs, ... }:
let
  inherit (inputs.nixpkgs) lib;
  nflib = import ../lib { inherit lib; };
in
{
  perSystem =
    { system, ... }:
    {
      packages =
        let
          pkgs = import inputs.nixpkgs {
            inherit system;
            config.allowUnfreePredicate =
              pkg:
              builtins.elem (lib.getName pkg) [
                "t3code"
              ];
          };

          # auto-discover all package directories
          x86OnlyPackages = [
            "agent-desktop"
            "arbor"
            "brave-origin"
            "kittylitter"
            "limux"
            "t3code"
            "voquill"
          ];
          packageDirs =
            lib.filter (path: system == "x86_64-linux" || !(builtins.elem (baseNameOf path) x86OnlyPackages))
              (
                nflib.scanPaths ./. {
                  exclude = [ ];
                }
              );

          # convert to attrset of callPackage calls
          packagesAttrset = lib.listToAttrs (
            map (path: {
              name = baseNameOf path;
              value = pkgs.callPackage path { };
            }) packageDirs
          );
        in
        packagesAttrset;
    };
}
