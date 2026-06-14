{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  makeWrapper,
  wrapGAppsHook4,
  gtk4,
  libadwaita,
  webkitgtk_6_0,
  nix-update-script,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "limux";
  version = "0.1.19";

  src = fetchurl {
    url = "https://github.com/am-will/limux/releases/download/v${finalAttrs.version}/limux-${finalAttrs.version}-linux-x86_64.tar.gz";
    hash = "sha256-94/s5Iugdf3vbiwwVviGhVe5tSBnDi4Cbsib3yzeNNg=";
  };

  nativeBuildInputs = [
    autoPatchelfHook
    makeWrapper
    wrapGAppsHook4
  ];

  buildInputs = [
    gtk4
    libadwaita
    webkitgtk_6_0
  ];

  installPhase = ''
    runHook preInstall

    install -Dm755 limux $out/bin/limux
    install -Dm755 lib/libghostty.so $out/lib/libghostty.so
    cp -r share $out/share

    runHook postInstall
  '';

  preFixup = ''
    gappsWrapperArgs+=(--prefix LD_LIBRARY_PATH : "$out/lib")
  '';

  passthru.updateScript = nix-update-script {
    extraArgs = [
      "--url"
      "https://github.com/am-will/limux"
      "--use-github-releases"
    ];
  };

  meta = {
    description = "GPU-accelerated terminal workspace manager for Linux";
    homepage = "https://github.com/am-will/limux";
    changelog = "https://github.com/am-will/limux/releases/tag/v${finalAttrs.version}";
    license = lib.licenses.mit;
    maintainers = [ ];
    platforms = [ "x86_64-linux" ];
    mainProgram = "limux";
  };
})
