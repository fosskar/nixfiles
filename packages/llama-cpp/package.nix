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
    version = "1.0.0";

    src = fetchFromGitHub {
      owner = "ggml-org";
      repo = "llama.cpp";
      tag = "v${finalAttrs.version}";
      hash = "sha256-aYziwYzK9Zj7sopAEsrANhMGs4BO0F2g0cDCGmYLxDA=";
    };

    npmDepsHash = "sha256-0OJIueUN5oD/V2NtVcXTiRW59u2tJIG3OxW8aJ8JDBY=";

    # needs numpy, torch and safetensors; covers the python gguf converter only
    disabledTests = old.disabledTests ++ [ "test-conversion-fp8" ];

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
