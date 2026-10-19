{
  lib,
  rustPlatform,
  fetchFromGitHub,
  fetchCrate,
  buildWasmBindgenCli,
  trunk,
  binaryen,
  llvmPackages,
  nix-update-script,
}:
let
  # trunk requires the wasm-bindgen version pinned in Cargo.lock; nixpkgs ships 0.2.127
  wasm-bindgen-cli = buildWasmBindgenCli rec {
    src = fetchCrate {
      pname = "wasm-bindgen-cli";
      version = "0.2.129";
      hash = "sha256-pcecKQd7E8Opw6bkFoE569epUi7gh5qpQF1e5PJY6V8=";
    };

    cargoDeps = rustPlatform.fetchCargoVendor {
      inherit src;
      inherit (src) pname version;
      hash = "sha256-vmUrWVU7kPJJxO5qIVeAkwQyWDELO1Z4Z5gitz2kco8=";
    };
  };
in
rustPlatform.buildRustPackage (finalAttrs: {
  pname = "vectorcraft-web";
  version = "0.13.1";

  src = fetchFromGitHub {
    owner = "storytold";
    repo = "vectorcraft";
    tag = "v${finalAttrs.version}";
    hash = "sha256-6fnvggL1zSNnO2w32zKpgtE2bv/4SWs//uAEDR+UFIo=";
  };

  cargoHash = "sha256-3bE4+qcKPubcfJ3ZDTKzqh+xT325qNFR08rSxRhny6E=";

  nativeBuildInputs = [
    trunk
    wasm-bindgen-cli
    binaryen
    llvmPackages.bintools-unwrapped
  ];

  buildPhase = ''
    runHook preBuild
    (cd apps/vectorcraft-web && HOME=$TMPDIR trunk build --offline --frozen --release)
    runHook postBuild
  '';

  passthru.updateScript = nix-update-script { };

  # the test suite targets the native workspace, not the wasm bundle
  doCheck = false;

  installPhase = ''
    runHook preInstall
    cp -r dist/web $out
    runHook postInstall
  '';

  meta = {
    description = "VectorCraft vector illustration editor compiled to WebAssembly, as a static site";
    homepage = "https://github.com/storytold/vectorcraft";
    license = with lib.licenses; [
      mit
      asl20
    ];
    platforms = lib.platforms.all;
  };
})
