{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  zstd,
  alsa-lib,
  curl,
  fontconfig,
  libglvnd,
  libxkbcommon,
  vulkan-loader,
  wayland,
  xdg-utils,
  libxi,
  libxcursor,
  libx11,
  libxcb,
  xz,
  zlib,
  makeWrapper,
  waylandSupport ? false,
}:

let
  pname = "warp-terminal";
  version = "0.2026.04.27.15.32.stable_03";

  linuxArch = if stdenv.hostPlatform.system == "x86_64-linux" then "x86_64" else "aarch64";

  hashes = {
    x86_64-linux = "sha256-N93S9SPPW9UhR3C3wlHpwvumnkj7Dx16x4TmKGxd/bc=";
    aarch64-linux = "sha256-09/GiuV4Tqal9qzvX4+GhhtbqrDNc1X5w/4j6vkd3Xo=";
  };
in
stdenv.mkDerivation {
  inherit pname version;

  src = fetchurl {
    url = "https://releases.warp.dev/stable/v${version}/warp-terminal-v${version}-1-${linuxArch}.pkg.tar.zst";
    hash = hashes.${stdenv.hostPlatform.system};
  };

  sourceRoot = ".";

  postPatch = ''
    substituteInPlace usr/bin/warp-terminal \
      --replace-fail /opt/ $out/opt/
  '';

  nativeBuildInputs = [
    autoPatchelfHook
    zstd
    makeWrapper
  ];

  buildInputs = [
    alsa-lib
    curl
    fontconfig
    stdenv.cc.cc.lib
    zlib
    xz
  ];

  runtimeDependencies = [
    libglvnd
    libxkbcommon
    stdenv.cc.libc
    vulkan-loader
    xdg-utils
    libx11
    libxcb
    libxcursor
    libxi
  ]
  ++ lib.optionals waylandSupport [ wayland ];

  installPhase = ''
    runHook preInstall

    mkdir $out
    cp -r opt usr/* $out
  ''
  + lib.optionalString waylandSupport ''
    wrapProgram $out/bin/warp-terminal --set WARP_ENABLE_WAYLAND 1
  ''
  + ''

    runHook postInstall
  '';

  postFixup = ''
    patchelf \
      --add-needed libfontconfig.so.1 \
      $out/opt/warpdotdev/warp-terminal/warp
  '';

  meta = {
    description = "agentic development environment, born out of the terminal";
    homepage = "https://github.com/warpdotdev/warp";
    license = [
      lib.licenses.agpl3Only
      lib.licenses.mit
    ];
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
    ];
    mainProgram = "warp-terminal";
  };
}
