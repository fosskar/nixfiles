{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  vulkan-loader,
  libGL,
  libxkbcommon,
  xorg,
  wayland,
  fontconfig,
  freetype,
  openssl,
  zlib,
  libgit2,
  libssh2,
}:
let
  pname = "arbor";
  version = "20260309.05";

  runtimeDeps = [
    vulkan-loader
    libGL
    libxkbcommon
    xorg.libxcb
    xorg.libX11
    xorg.libXcursor
    xorg.libXrandr
    xorg.libXi
    wayland
    fontconfig
    freetype
    openssl
    zlib
    libgit2
    libssh2
  ];
in
stdenv.mkDerivation {
  inherit pname version;

  src = fetchurl {
    url = "https://github.com/penso/arbor/releases/download/${version}/Arbor-${version}-x86_64-unknown-linux-gnu.tar.gz";
    hash = "sha256-/WdYKyb4wCCKndrTgS/spC2rzFJ1qD/x9qUVwosaOcc=";
  };

  nativeBuildInputs = [ autoPatchelfHook ];
  buildInputs = runtimeDeps;

  sourceRoot = "Arbor-${version}-x86_64-unknown-linux-gnu";

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin $out/share
    cp bin/Arbor $out/bin/arbor
    cp bin/arbor-httpd $out/bin/arbor-httpd
    cp bin/arbor-mcp $out/bin/arbor-mcp
    cp -r share/arbor $out/share/arbor

    runHook postInstall
  '';

  postFixup = ''
    for bin in $out/bin/arbor $out/bin/arbor-httpd $out/bin/arbor-mcp; do
      patchelf --add-rpath "${lib.makeLibraryPath runtimeDeps}" "$bin"
    done
  '';

  meta = {
    description = "native desktop app for agentic coding with git worktrees, terminals, and diffs";
    homepage = "https://github.com/penso/arbor";
    license = lib.licenses.mit;
    platforms = [ "x86_64-linux" ];
    mainProgram = "arbor";
  };
}
