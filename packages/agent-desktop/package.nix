{
  lib,
  rustPlatform,
  fetchFromGitHub,
  nix-update-script,
}:
rustPlatform.buildRustPackage (finalAttrs: {
  pname = "agent-desktop";
  version = "1.3.1";

  src = fetchFromGitHub {
    owner = "vercel-labs";
    repo = "agent-desktop";
    tag = "v${finalAttrs.version}";
    hash = "sha256-/SZ2AR1ww8pcUeffEk1Np24M3roiS1yXNQyCle82T5Q=";
  };

  cargoHash = "sha256-VlPyMlUtTm7v3AHbCiippZLAOGM4yH3+Oc2B9ZAOJ1g=";

  # each platform adapter builds only on its own os, so scope cargo to the linux packages
  cargoBuildFlags = [
    "-p"
    "agent-desktop"
    "-p"
    "agent-desktop-linux"
  ];
  # the linux adapter tests need an at-spi session bus
  cargoTestFlags = [
    "-p"
    "agent-desktop-core"
  ];

  # the trace tests resolve the state root under $HOME
  preCheck = ''
    export HOME=$(mktemp -d)
  '';

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "Computer use for AI agents through the OS accessibility tree";
    homepage = "https://github.com/vercel-labs/agent-desktop";
    changelog = "https://github.com/vercel-labs/agent-desktop/releases/tag/v${finalAttrs.version}";
    license = lib.licenses.asl20;
    mainProgram = "agent-desktop";
    platforms = lib.platforms.linux;
  };
})
