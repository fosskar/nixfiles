{
  lib,
  rustPlatform,
  fetchFromGitHub,
  zig_0_16,
  pkg-config,
  makeBinaryWrapper,
  copyDesktopItems,
  makeDesktopItem,
  fontconfig,
  freetype,
  libxkbcommon,
  wayland,
  libxcb,
  libx11,
  vulkan-loader,
  herdr-core,
  nix-update-script,
}:
rustPlatform.buildRustPackage (finalAttrs: {
  pname = "herdr-app";
  version = "0.1.11";

  src = fetchFromGitHub {
    owner = "herdrdev";
    repo = "herdr-app";
    tag = "v${finalAttrs.version}";
    fetchSubmodules = true;
    hash = "sha256-vuY2a3iGVJ8+oOXnQbWY5/hYNUdCov5yDuttCq9swr4=";
  };

  cargoHash = "sha256-DX4+ELg1vtprKv8N6R8rW42wty+hKMo96/MxiiUmqu8=";

  # crates/ghostty-sys/build.rs runs `zig build` offline against this cache
  zigDeps = zig_0_16.fetchDeps {
    inherit (finalAttrs) pname version;
    src = "${finalAttrs.src}/vendor/ghostty";
    fetchAll = true;
    hash = "sha256-G9xbZ/pyQTDIfzG0h++i70a45zpwyYpZMBZfAnoOQw0=";
  };

  nativeBuildInputs = [
    zig_0_16
    pkg-config
    makeBinaryWrapper
    copyDesktopItems
    rustPlatform.bindgenHook
  ];

  buildInputs = [
    fontconfig
    freetype
    libxkbcommon
    wayland
    libxcb
    libx11
  ];

  # zig is only called from build.rs; keep cargo's phases
  dontUseZigBuild = true;
  dontUseZigInstall = true;
  dontUseZigCheck = true;
  dontUseZigConfigure = true;

  # an explicit -Dtarget makes zig link build-time helpers against the FHS
  # loader; build natively with a baseline cpu instead.
  # bundled zig runtimes cause overlapping FDEs with ld.bfd 2.46.
  # bindgenHook supplies clang's builtin and libc headers; zig's clash with them.
  postPatch = ''
    substituteInPlace crates/ghostty-sys/build.rs \
      --replace-fail 'else if Command::new("clang").arg("--version").output().is_err() {' 'else if false {' \
      --replace-fail '.args(["build", "-Demit-lib-vt", "-Doptimize=ReleaseFast"])' \
        '.args(["build", "-Demit-lib-vt", "-Doptimize=ReleaseFast", "-Dcpu=baseline"])' \
      --replace-fail '.arg(format!("-Dtarget={}", zig_target(&std::env::var("TARGET").unwrap())))' ""
    substituteInPlace vendor/ghostty/src/build/GhosttyLibVt.zig \
      --replace-fail 'lib.bundle_compiler_rt = true;' 'lib.bundle_compiler_rt = false;' \
      --replace-fail 'lib.bundle_ubsan_rt = true;' 'lib.bundle_ubsan_rt = false;'
  '';

  preBuild = ''
    export ZIG_GLOBAL_CACHE_DIR="$TMPDIR/zig-global-cache"
    export ZIG_LOCAL_CACHE_DIR="$TMPDIR/zig-local-cache"
    mkdir -p "$ZIG_GLOBAL_CACHE_DIR" "$ZIG_LOCAL_CACHE_DIR"
    cp -rL ${finalAttrs.zigDeps} "$ZIG_GLOBAL_CACHE_DIR/p"
    chmod -R u+w "$ZIG_GLOBAL_CACHE_DIR/p"
  '';

  cargoBuildFlags = [ "--package=herdr-app" ];

  # render and pty tests need a display and terminals
  doCheck = false;

  desktopItems = [
    (makeDesktopItem {
      name = "herdr-app";
      desktopName = "Herdr";
      comment = "Terminals and coding agents that keep running";
      exec = "herdr-app";
      icon = "herdr-app";
      startupWMClass = "herdr-app";
      categories = [ "Development" ];
    })
  ];

  postInstall = ''
    install -Dm444 assets/icons/herdr-ui-icon-clean.svg \
      $out/share/icons/hicolor/scalable/apps/herdr-app.svg
  '';

  # gpui dlopens vulkan, wayland and xkbcommon; hc on PATH keeps the app from
  # offering to install its own core into ~/.local/bin
  postFixup = ''
    patchelf $out/bin/herdr-app --add-rpath ${
      lib.makeLibraryPath [
        vulkan-loader
        wayland
        libxkbcommon
        libxcb
        libx11
      ]
    }
    wrapProgram $out/bin/herdr-app --prefix PATH : ${lib.makeBinPath [ herdr-core ]}
  '';

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "Desktop app for terminals and coding agents, built on herdr-core";
    homepage = "https://herdr.dev";
    changelog = "https://github.com/herdrdev/herdr-app/releases/tag/v${finalAttrs.version}";
    license = lib.licenses.asl20;
    mainProgram = "herdr-app";
    platforms = lib.platforms.linux;
  };
})
