{
  lib,
  stdenvNoCC,
  rustPlatform,
  fetchFromGitHub,
  fetchPnpmDeps,
  pnpm_10,
  pnpmConfigHook,
  nodejs,
  cmake,
  makeBinaryWrapper,
  ffmpeg,
  nix-update-script,
}:
let
  pname = "droppedneedle";
  version = "3.1.0";

  src = fetchFromGitHub {
    owner = "DroppedNeedle";
    repo = "DroppedNeedle";
    tag = "v${version}";
    hash = "sha256-dgL8w8P6e2hcpWUMGHwM8k+HCJhzETiSFVM53YDSoNU=";
  };

  frontend = stdenvNoCC.mkDerivation (finalAttrs: {
    pname = "${pname}-frontend";
    inherit version src;
    sourceRoot = "${src.name}/frontend";

    pnpmDeps = fetchPnpmDeps {
      inherit (finalAttrs) pname version src;
      sourceRoot = "${src.name}/frontend";
      pnpm = pnpm_10;
      fetcherVersion = 3;
      hash = "sha256-VCC8/D948fx+cgaIMhX/M7etOysAWXEFa/wKJ/TXNbE=";
    };

    nativeBuildInputs = [
      nodejs
      pnpm_10
      pnpmConfigHook
    ];

    # the server stamps BASE_PATH into the placeholder at startup and refuses a build without it
    env.DROPPEDNEEDLE_BASE_PATH_PLACEHOLDER = "1";

    buildPhase = ''
      runHook preBuild
      pnpm run build
      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall
      cp -r build $out
      runHook postInstall
    '';
  });
in
rustPlatform.buildRustPackage {
  inherit pname version src;

  # the build also reads ../sdk and ../frontend/src/lib/stores/customCssRules.json
  sourceRoot = "${src.name}/server";

  cargoHash = "sha256-4I5YjmqGwPEwteBKuK0qI9FkAvQvWXaK29dvJ6Q70Dk=";

  cargoBuildFlags = [
    "-p"
    "droppedneedle"
    "-p"
    "droppedneedle-tool"
  ];
  # upstream's suite has timing windows a loaded builder misses, and tests
  # that need debug builds or files outside the sandbox
  doCheck = false;

  # opusic-sys builds its bundled libopus through the cmake crate
  nativeBuildInputs = [
    cmake
    makeBinaryWrapper
  ];
  dontUseCmakeConfigure = true;

  # build the bundled sqlite with the flags of upstream's Dockerfile; the
  # cargo setup hook would link the system sqlite instead
  env.LIBSQLITE3_FLAGS = "-DSQLITE_DEFAULT_MEMSTATUS=0";
  postConfigure = ''
    export LIBSQLITE3_SYS_USE_PKG_CONFIG=0
  '';

  # the web ui is copied out of the read-only store and then rewritten in place,
  # and fs::copy keeps the 0444 mode
  postPatch = ''
    substituteInPlace src/web.rs \
      --replace-fail \
        'std::fs::copy(&source, &target).map_err(io_error(&source))?;' \
        'std::fs::copy(&source, &target).map_err(io_error(&source))?;
            std::fs::set_permissions(&target, std::os::unix::fs::PermissionsExt::from_mode(0o644)).map_err(io_error(&target))?;'
  '';

  # the server finds droppedneedle-tool beside its own executable
  postInstall = ''
    wrapProgram $out/bin/droppedneedle \
      --prefix PATH : ${lib.makeBinPath [ ffmpeg ]} \
      --set-default DROPPEDNEEDLE_STATIC_DIR ${frontend}
  '';

  passthru = {
    inherit frontend;
    updateScript = nix-update-script {
      extraArgs = [
        "--subpackage"
        "frontend"
      ];
    };
  };

  meta = {
    description = "Self-hosted music request and library engine";
    homepage = "https://droppedneedle.com";
    license = lib.licenses.agpl3Plus;
    mainProgram = "droppedneedle";
    platforms = lib.platforms.linux;
  };
}
