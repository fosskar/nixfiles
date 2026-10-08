{
  lib,
  stdenvNoCC,
  fetchzip,
  nix-update-script,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "opencloud-web-unzip";
  version = "2.2.1";

  src = fetchzip {
    url = "https://github.com/opencloud-eu/web-extensions/releases/download/unzip-v${finalAttrs.version}/unzip-${finalAttrs.version}.zip";
    hash = "sha256-fRmuIyP2HapfOdkU/90pCt78hmxe6DAB1E17qpGiwEE=";
  };

  dontConfigure = true;
  dontBuild = true;
  dontFixup = true;

  installPhase = ''
    runHook preInstall
    cp -r . $out
    runHook postInstall
  '';

  # the repo releases every extension under its own <app>-v<version> tag
  passthru.updateScript = nix-update-script {
    extraArgs = [
      "--version-regex"
      "^unzip-v(\\d+\\.\\d+\\.\\d+)$"
    ];
  };

  meta = {
    description = "OpenCloud web extension: unzip";
    homepage = "https://github.com/opencloud-eu/web-extensions";
    license = lib.licenses.agpl3Only;
  };
})
