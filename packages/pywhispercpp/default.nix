{
  lib,
  python3Packages,
  fetchFromGitHub,
  cmake,
  ninja,
  pkg-config,
  # GPU backends
  vulkan-loader,
  vulkan-headers,
  shaderc,
  enableVulkan ? true,
}:
python3Packages.buildPythonPackage rec {
  pname = "pywhispercpp";
  version = "1.4.1";
  format = "setuptools";

  src = fetchFromGitHub {
    owner = "absadiki";
    repo = "pywhispercpp";
    tag = "v${version}";
    hash = "sha256-8PhI6YDpJQ4F2M96ehG95C/SJ7ZbmyZ0KprgjWjQEzQ=";
    fetchSubmodules = true;
  };

  # cmake/ninja needed by setup.py, not as nix build phases
  nativeBuildInputs = [
    cmake
    ninja
    pkg-config
  ]
  ++ lib.optionals enableVulkan [
    shaderc # for glslc in PATH
  ];

  buildInputs = lib.optionals enableVulkan [
    vulkan-loader
    vulkan-headers
  ];

  dependencies = with python3Packages; [
    numpy
    requests
    tqdm
    platformdirs
  ];

  # don't run cmake configure phase - setup.py handles it
  dontUseCmakeConfigure = true;

  # patch out repairwheel - not needed on nixos, nix handles library paths
  postPatch = ''
    substituteInPlace setup.py \
      --replace-fail "self.repair_wheel()" "pass  # self.repair_wheel()"
  '';

  env = {
    CMAKE_GENERATOR = "Ninja";
  }
  // lib.optionalAttrs enableVulkan {
    GGML_VULKAN = "1";
  };

  # don't run tests - they need audio/model files
  doCheck = false;

  # fix RPATH references to /build/
  preFixup = ''
    for lib in $out/lib/python*/site-packages/*.so*; do
      patchelf --shrink-rpath --allowed-rpath-prefixes /nix/store "$lib" || true
    done
  '';

  pythonImportsCheck = [ "pywhispercpp" ];

  meta = {
    description = "Python bindings for whisper.cpp";
    homepage = "https://github.com/absadiki/pywhispercpp";
    license = lib.licenses.mit;
    maintainers = [ ];
    platforms = lib.platforms.linux;
  };
}
