{ inputs, ... }:
let
  inherit (inputs.nixpkgs) lib;
  mylib = import ../lib { inherit lib; };
in
{
  flake.overlays.default =
    final: _prev:
    let
      packageDirs = mylib.scanPaths ../packages {
        exclude = [
          "onnxruntime-openvino" # python package, needs special handling
        ];
      };
    in
    lib.listToAttrs (
      map (path: {
        name = "custom-${baseNameOf path}";
        value = final.callPackage path { };
      }) packageDirs
    );
}
