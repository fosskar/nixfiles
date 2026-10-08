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
    version = "0.6.0";

    src = fetchFromGitHub {
      owner = "ggml-org";
      repo = "llama.cpp";
      tag = "v${finalAttrs.version}";
      hash = "sha256-l6l6JIlIVTaVC6xh5M4fRHFtXsweQuugtkNTWHcZZF4=";
    };

    npmDepsHash = "sha256-a17M+L3nLdRnN6WMB6imPFmwqG2g8uv+gwN0XTAUrf8=";

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
