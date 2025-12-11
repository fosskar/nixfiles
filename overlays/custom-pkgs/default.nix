final: _prev:
let
  inherit (final) lib;
  mylib = import ../../lib { inherit lib; };
  packageDirs = mylib.scanPaths ../../packages {
    exclude = [
      "onnxruntime-openvino" # python package, needs special handling
    ];
  };
in
{
  custom = lib.listToAttrs (
    map (path: {
      name = baseNameOf path;
      value = final.callPackage path { };
    }) packageDirs
  );
}
