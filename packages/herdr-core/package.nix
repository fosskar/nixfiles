{
  lib,
  rustPlatform,
  fetchFromGitHub,
  zig_0_16,
  nix-update-script,
}:
rustPlatform.buildRustPackage (finalAttrs: {
  pname = "herdr-core";
  version = "0.1.17";

  src = fetchFromGitHub {
    owner = "herdrdev";
    repo = "herdr-core";
    tag = "v${finalAttrs.version}";
    fetchSubmodules = true;
    hash = "sha256-fulACGl26Pk6FAvOOJsFtPfFQMwJAfw/MqMa6Rq0/4c=";
  };

  cargoHash = "sha256-UZsc5AElm5gmIImgR8cZz0U9+2RNG+DRb+OU8ifZSXc=";

  # crates/ghostty-vt/build.rs runs `zig build` offline against this cache
  zigDeps = zig_0_16.fetchDeps {
    inherit (finalAttrs) pname version;
    src = "${finalAttrs.src}/vendor/ghostty";
    fetchAll = true;
    hash = "sha256-G9xbZ/pyQTDIfzG0h++i70a45zpwyYpZMBZfAnoOQw0=";
  };

  nativeBuildInputs = [ zig_0_16 ];

  # zig is only called from build.rs; keep cargo's phases
  dontUseZigBuild = true;
  dontUseZigInstall = true;
  dontUseZigCheck = true;
  dontUseZigConfigure = true;

  # bundled zig runtimes cause overlapping FDEs with ld.bfd 2.46
  postPatch = ''
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

  # tests spawn PTYs and daemons
  doCheck = false;

  # herdr-app and agents call the core as `hc`
  postInstall = ''
    ln -s herdr-core $out/bin/hc
  '';

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "Terminal runtime for coding agents";
    homepage = "https://herdr.dev/core";
    changelog = "https://github.com/herdrdev/herdr-core/releases/tag/v${finalAttrs.version}";
    license = lib.licenses.asl20;
    mainProgram = "hc";
    platforms = lib.platforms.linux ++ lib.platforms.darwin;
  };
})
