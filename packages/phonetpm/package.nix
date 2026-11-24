{
  lib,
  rustPlatform,
  fetchFromGitHub,
  nix-update-script,
}:
rustPlatform.buildRustPackage (finalAttrs: {
  pname = "phonetpm";
  version = "0.4.2";

  src = fetchFromGitHub {
    owner = "Lassulus";
    repo = "phonetpm";
    tag = "v${finalAttrs.version}";
    hash = "sha256-SCrCuaeAwx7bs3Y8IXmOf5Zwx3UudTX52ODCrnm2iKM=";
  };

  cargoHash = "sha256-pTgkA+jc+G8GxiDsVHP5q9Zt55k1nyr1ltAAqRXEpqc=";

  # host side only; the workspace also holds the android core
  cargoBuildFlags = [
    "-p"
    "phonetpm"
  ];
  cargoTestFlags = finalAttrs.cargoBuildFlags;

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "Android phone as a biometric ssh-agent and age backend over iroh";
    homepage = "https://github.com/Lassulus/phonetpm";
    license = lib.licenses.mit;
    mainProgram = "phonetpm";
    platforms = lib.platforms.linux;
  };
})
