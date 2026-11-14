{
  lib,
  pkgs,
  fetchFromGitHub,
  nix-update-script,
  cudaSupport ? true,
  vulkanSupport ? true,
  rpcSupport ? true,
}:
# one build for every host: GGML_BACKEND_DL loads the cuda backend on nixbox
# and the vulkan backend on nixworker at runtime. the llama-cpp router and
# its rpc servers must run the same build: the ggml rpc protocol is versioned
(pkgs.llama-cpp.override { inherit cudaSupport vulkanSupport rpcSupport; }).overrideAttrs (
  finalAttrs: old: {
    version = "1.0.0";

    src = fetchFromGitHub {
      owner = "ggml-org";
      repo = "llama.cpp";
      tag = "v${finalAttrs.version}";
      hash = "sha256-aYziwYzK9Zj7sopAEsrANhMGs4BO0F2g0cDCGmYLxDA=";
    };

    npmDepsHash = "sha256-0OJIueUN5oD/V2NtVcXTiRW59u2tJIG3OxW8aJ8JDBY=";

    # nixbox's gpu (cudaCapabilities 12.0 in nvidia.nix); the flake pkgs keep
    # the default capabilities, which compile kernels for every architecture
    cmakeFlags =
      lib.filter (flag: !lib.hasPrefix "-DCMAKE_CUDA_ARCHITECTURES" flag) old.cmakeFlags
      ++ lib.optional cudaSupport (lib.cmakeFeature "CMAKE_CUDA_ARCHITECTURES" "120");

    # need torch and transformers; cover the python gguf converter, which is not installed
    disabledTests = old.disabledTests ++ [
      "test-conversion-fp8"
      "test-kv-cache-scales"
    ];

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
