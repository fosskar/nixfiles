{
  lib,
  rustPlatform,
  fetchFromGitHub,
  fetchCrate,
  buildWasmBindgenCli,
  trunk,
  binaryen,
  llvmPackages,
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
  pname = "photocraft-web";
  version = "0.3.0";

  src = fetchFromGitHub {
    owner = "storytold";
    repo = "photocraft";
    tag = "v${finalAttrs.version}";
    hash = "sha256-MpvMiONXNd3w/NUQI3xZ8SKJFor42w0sxHHEFHnXgGw=";
  };

  cargoHash = "sha256-GytJ3eaPf18GDgAPxbKCZ6ibrxzLcnht4KLC/0UxrbM=";

  nativeBuildInputs = [
    trunk
    wasm-bindgen-cli
    binaryen
    llvmPackages.bintools-unwrapped
  ];

  env.PHOTOCRAFT_BUILD_SHA = finalAttrs.src.tag;

  buildPhase = ''
    runHook preBuild
    (cd apps/photocraft-web && HOME=$TMPDIR trunk build --offline --frozen --release)
    runHook postBuild
  '';

  # the test suite targets the native workspace, not the wasm bundle
  doCheck = false;

  installPhase = ''
    runHook preInstall
    cp -r dist/web $out
    runHook postInstall
  '';

  meta = {
    description = "PhotoCraft image editor compiled to WebAssembly, as a static site";
    homepage = "https://github.com/storytold/photocraft";
    license = with lib.licenses; [
      mit
      asl20
    ];
    platforms = lib.platforms.all;
  };
})
