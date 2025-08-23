{
  lib,
  stdenv,
  fetchFromGitHub,
  rustPlatform,
  bun,
  pkg-config,
  webkitgtk_4_1,
  gtk3,
  libayatana-appindicator,
  librsvg,
  openssl,
  xdotool,
  libsoup_3,
  dbus,
  cargo,
  rustc,
  nodejs,
  jq,
  claude-code,
}:

rustPlatform.buildRustPackage rec {
  pname = "claudia";
  version = "0-unstable-2025-07-29";

  src = fetchFromGitHub {
    owner = "getAsterisk";
    repo = "claudia";
    rev = "16acda5644f200eecfd18ed88f750918fe7b6b57";
    hash = "sha256-1Y6x/rzz4eWauoC+uHdGiv0cwuitEDxumXOCuFjjyGM=";
  };

  cargoRoot = "src-tauri";

  cargoHash = "sha256-unVKAZ71CvxVqUCBFMKqgKreHXUBae3+Qy5Fw8fMcl8=";

  bunDeps = stdenv.mkDerivation {
    pname = "${pname}-bun-deps";
    inherit src version;
    nativeBuildInputs = [
      bun
      nodejs
    ];

    outputHashMode = "recursive";
    outputHashAlgo = "sha256";
    outputHash = "sha256-SyE9rdIOzNhwhDU1zKGFqHTsKNdBRkda5QJ5P6gA2UU=";

    installPhase = ''
      cp ${src}/bun.lock .
      cp ${src}/package.json .
      mkdir -p src-tauri
      cp -r ${src}/src-tauri/* src-tauri/

      bun install --frozen-lockfile
      patchShebangs node_modules/.bin

      # remove broken cache symlinks that point to /build directory
      find node_modules -name ".cache" -type d -exec rm -rf {} + 2>/dev/null || true

      mkdir -p $out
      mv node_modules $out/
    '';
  };

  nativeBuildInputs = [
    rustPlatform.cargoSetupHook
    bun
    pkg-config
    cargo
    rustc
    nodejs
    jq
  ];

  buildInputs = [
    webkitgtk_4_1
    gtk3
    libayatana-appindicator
    librsvg
    openssl
    xdotool
    libsoup_3
    dbus
  ];

  postUnpack = ''
    # Create the binaries directory and link claude-code binary before cargo build
    # The Tauri build script runs from src-tauri directory, so we need binaries/ relative to that
    mkdir -p source/src-tauri/binaries
    cp ${claude-code}/bin/claude source/src-tauri/binaries/claude-code-x86_64-unknown-linux-gnu
    chmod +x source/src-tauri/binaries/claude-code-x86_64-unknown-linux-gnu
  '';

  preBuild = ''
    ln -s ${bunDeps}/node_modules ./node_modules
  '';

  buildPhase = ''
    runHook preBuild

    # this prevents the tauri cli from running beforeBuildCommand
    jq '.build.beforeBuildCommand = ""' src-tauri/tauri.conf.json > src-tauri/tauri.conf.json.tmp
    mv src-tauri/tauri.conf.json.tmp src-tauri/tauri.conf.json

    node ./node_modules/.bin/tsc
    node ./node_modules/.bin/vite build

    node ./node_modules/.bin/tauri build --no-bundle

    runHook postBuild
  '';

  checkPhase = ''
    runHook preCheck

    cd src-tauri
    cargo test $cargoCheckFlags

    runHook postCheck
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin
    install -Dm755 target/release/claudia $out/bin/claudia
    runHook postInstall
  '';

  meta = {
    description = "Powerful GUI app and Toolkit for Claude Code";
    homepage = "https://github.com/getAsterisk/claudia";
    license = lib.licenses.agpl3Only;
    maintainers = [ lib.maintainers.codebam ];
    platforms = lib.platforms.linux;
  };
}
