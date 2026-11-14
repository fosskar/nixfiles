{
  pkgs,
  fetchFromGitHub,
  nix-update-script,
  cudaSupport ? false,
  vulkanSupport ? false,
  rpcSupport ? false,
}:
# the llama-cpp router and its rpc servers must run the same build: the
# ggml rpc protocol is versioned
(pkgs.llama-cpp.override { inherit cudaSupport vulkanSupport rpcSupport; }).overrideAttrs (
  finalAttrs: old: {
    version = "0.9.0";

    src = fetchFromGitHub {
      owner = "ggml-org";
      repo = "llama.cpp";
      tag = "v${finalAttrs.version}";
      hash = "sha256-6LqtpfqTAbYUr/wPPBAM/dXHv3LDTg+1A81k/cFcAjY=";
    };

    npmDepsHash = "sha256-XLtEZsSFdk+2SyfXzBp8HQ2e27PQPpDCn1YjePU1/9w=";

    # needs numpy, torch and safetensors; covers the python gguf converter only
    disabledTests = old.disabledTests ++ [ "test-conversion-fp8" ];

    # skip the package-llama-cpp check: hosts ship only the cuda and vulkan
    # variants, which nixos-nixbox and nixos-nixworker already build and test
    meta = old.meta // {
      hydraPlatforms = [ ];
    };

    # semver releases only; upstream also tags every nightly build as
    # b<number>, which pushes semver releases out of the atom feed
    passthru = old.passthru // {
      updateScript = nix-update-script {
        extraArgs = [
          "--use-github-releases"
          "--version-regex"
          "^v(\\d+\\.\\d+\\.\\d+)$"
        ];
      };
    };
  }
)
