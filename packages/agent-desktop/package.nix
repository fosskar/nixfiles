{
  lib,
  rustPlatform,
  fetchFromGitHub,
  nix-update-script,
}:
rustPlatform.buildRustPackage (finalAttrs: {
  pname = "agent-desktop";
  version = "1.1.0";

  src = fetchFromGitHub {
    owner = "vercel-labs";
    repo = "agent-desktop";
    tag = "v${finalAttrs.version}";
    hash = "sha256-7v0x74sFO1SVFS/aw7QalWkLmLDpGhY0v83x9JLlzUI=";
  };

  cargoHash = "sha256-ye/FmVkXY54eeLejXYHljJofJm8GsoUeDUDMrPx69ug=";

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
