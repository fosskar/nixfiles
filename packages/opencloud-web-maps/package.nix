{
  lib,
  stdenvNoCC,
  fetchzip,
  nix-update-script,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "opencloud-web-maps";
  version = "3.1.0";

  src = fetchzip {
    url = "https://github.com/opencloud-eu/web-extensions/releases/download/maps-v${finalAttrs.version}/maps-${finalAttrs.version}.zip";
    hash = "sha256-rVZaF1OiJvW/XmBh7tUgTxsQ+0cn9WON2tRg+5SeTM4=";
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
      "^maps-v(\\d+\\.\\d+\\.\\d+)$"
    ];
  };

  meta = {
    description = "OpenCloud web extension: maps";
    homepage = "https://github.com/opencloud-eu/web-extensions";
    license = lib.licenses.agpl3Only;
  };
})
