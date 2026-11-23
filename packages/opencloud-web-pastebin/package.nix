{
  lib,
  stdenvNoCC,
  fetchzip,
  nix-update-script,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "opencloud-web-pastebin";
  version = "2.2.1";

  src = fetchzip {
    url = "https://github.com/opencloud-eu/web-extensions/releases/download/pastebin-v${finalAttrs.version}/pastebin-${finalAttrs.version}.zip";
    hash = "sha256-kK6SeLgbDO8hJ3KkeakrXpIa4R5J8dToH4o0k3mYsxE=";
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
      "^pastebin-v(\\d+\\.\\d+\\.\\d+)$"
    ];
  };

  meta = {
    description = "OpenCloud web extension: pastebin";
    homepage = "https://github.com/opencloud-eu/web-extensions";
    license = lib.licenses.agpl3Only;
  };
})
