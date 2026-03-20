{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  makeWrapper,
  makeDesktopItem,
  copyDesktopItems,
  vulkan-loader,
  libGL,
  libxkbcommon,
  wayland,
  zlib,
  gcc-unwrapped,
  fontconfig,
  freetype,
  git,
  openssh,
  libxcb,
  avahi,
  zsh,
}:
let
  pname = "arbor";
  version = "20260316.01";

  runtimeDeps = [
    vulkan-loader
    libGL
    libxkbcommon
    libxcb
    wayland
    fontconfig
    freetype
    zlib
    gcc-unwrapped.lib
    avahi
  ];
in
stdenv.mkDerivation {
  inherit pname version;

  src = fetchurl {
    url = "https://github.com/penso/arbor/releases/download/${version}/Arbor-${version}-x86_64-unknown-linux-gnu.tar.gz";
    hash = "sha256-tXcG939wBBAXaUHDBqSfz8utIqkHFH05agtQQqqtiI4=";
  };

  desktopItems = [
    (makeDesktopItem {
      name = "arbor";
      desktopName = "Arbor";
      comment = "agentic coding with git worktrees, terminals, and diffs";
      exec = "arbor";
      terminal = false;
      categories = [
        "Development"
        "IDE"
      ];
    })
  ];

  nativeBuildInputs = [
    autoPatchelfHook
    copyDesktopItems
    makeWrapper
  ];
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
      wrapProgram "$bin" \
        --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath runtimeDeps}" \
        --prefix PATH : "${
          lib.makeBinPath [
            git
            openssh
          ]
        }"
    done
    # use zsh for embedded terminal (fish has DA1 query issues with arbor's terminal emulator)
    wrapProgram $out/bin/arbor --set SHELL "${zsh}/bin/zsh"
  '';

  meta = {
    description = "native desktop app for agentic coding with git worktrees, terminals, and diffs";
    homepage = "https://github.com/penso/arbor";
    license = lib.licenses.mit;
    platforms = [ "x86_64-linux" ];
    mainProgram = "arbor";
  };
}
