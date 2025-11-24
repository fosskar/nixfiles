{
  buildPythonPackage,
  fetchPypi,
  coloredlogs,
  flatbuffers,
  numpy,
  packaging,
  protobuf,
  sympy,
}:
buildPythonPackage rec {
  pname = "onnxruntime-openvino";
  version = "1.20.0";
  format = "wheel";

  # the build distribution doesn't work at all, it seems to expect the same structure
  # as the github source repo.
  # The github source wasn't immediately obvious how to build for this subpackage.
  src = fetchPypi {
    pname = "onnxruntime_openvino";
    inherit version format;
    dist = "cp312";
    python = "cp312";
    abi = "cp312";
    platform = "manylinux_2_28_x86_64";
    hash = "sha256-l/QksF/rGLTbtumoXSv71MkoUI3IhGYiscErQIbOk3w=";
  };

  propagatedBuildInputs = [
    coloredlogs
    flatbuffers
    numpy
    packaging
    protobuf
    sympy
  ];

  # pythonImportsCheck = ["onnxruntime-openvino"];
}
# https://files.pythonhosted.org/packages/3d/0b/d967ac3db4ff8edfd658c27c5e533f2095784a0536f5a98df3a1eb8f7681/onnxruntime_openvino-1.20.0-cp312-cp312-manylinux_2_28_x86_64.whl
