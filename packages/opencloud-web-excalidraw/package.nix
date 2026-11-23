{
  lib,
  stdenvNoCC,
  fetchzip,
  nix-update-script,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "opencloud-web-excalidraw";
  version = "1.2.0";

  src = fetchzip {
    url = "https://github.com/opencloud-eu/web-extensions/releases/download/excalidraw-v${finalAttrs.version}/excalidraw-${finalAttrs.version}.zip";
    hash = "sha256-9t/WHVbTWrWm6o96vjidwIQtP1+JCCqmKxlnwZUAjnY=";
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
      "^excalidraw-v(\\d+\\.\\d+\\.\\d+)$"
    ];
  };

  meta = {
    description = "OpenCloud web extension: excalidraw";
    homepage = "https://github.com/opencloud-eu/web-extensions";
    license = lib.licenses.agpl3Only;
  };
})
