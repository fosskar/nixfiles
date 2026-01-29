final: _prev:
let
  inherit (final) lib;
  mylib = import ../../lib { inherit lib; };
  packageDirs = mylib.scanPaths ../../packages {
    exclude = [
      "onnxruntime-openvino" # python package, needs special handling
    ];
  };
  # extra args for specific packages
  extraArgs = {
    stirling-pdf = {
      isDesktopVariant = false;
    };
  };
in
{
  custom = lib.listToAttrs (
    map (path: {
      name = baseNameOf path;
      value = final.callPackage path (extraArgs.${baseNameOf path} or { });
    }) packageDirs
  );
}
