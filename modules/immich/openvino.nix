# immich with openvino ML acceleration
{ lib, pkgs }:
let
  onnxruntime =
    (pkgs.onnxruntime.override {
      python3Packages = pkgs.python312Packages;
    }).overrideAttrs
      (oldAttrs: {
        buildInputs = (oldAttrs.buildInputs or [ ]) ++ [
          pkgs.openvino
        ];

        nativeBuildInputs = (oldAttrs.nativeBuildInputs or [ ]) ++ [
          pkgs.patchelf
        ];

        cmakeFlags = (oldAttrs.cmakeFlags or [ ]) ++ [
          (lib.cmakeBool "onnxruntime_USE_OPENVINO" true)
          (lib.cmakeFeature "OpenVINO_DIR" "${pkgs.openvino}/runtime/cmake")
        ];

        # openvino loads some frontends dynamically, so onnxruntime's provider must
        # retain a runtime path to openvino libs after fixup.
        postFixup = (oldAttrs.postFixup or "") + ''
          provider="''${!outputLib}/lib/libonnxruntime_providers_openvino.so"
          if [ -e "$provider" ]; then
            patchelf --add-rpath "${pkgs.openvino}/runtime/lib/intel64" "$provider"
          fi
        '';

        doCheck = false;
      });

  python312 = pkgs.python312.override {
    packageOverrides = _pyFinal: pyPrev: {
      onnxruntime =
        (pyPrev.onnxruntime.override {
          inherit onnxruntime;
        }).overrideAttrs
          (oldAttrs: {
            buildInputs = (oldAttrs.buildInputs or [ ]) ++ [
              pkgs.openvino
            ];
          });
      # openvino pythonImportsCheck needs gpu/opencl unavailable in sandbox
      openvino = pyPrev.openvino.overrideAttrs (_: {
        doInstallCheck = false;
      });
    };
  };

  machineLearning =
    (pkgs.immich-machine-learning.override {
      python3 = python312;
    }).overrideAttrs
      (_: {
        doCheck = false;
      });

  immich = pkgs.immich.override {
    immich-machine-learning = machineLearning;
  };
in
immich.overrideAttrs (oldAttrs: {
  passthru = oldAttrs.passthru // {
    machine-learning = oldAttrs.passthru.machine-learning.overrideAttrs (_: {
      doCheck = false;
      doInstallCheck = false;
    });
  };
})
