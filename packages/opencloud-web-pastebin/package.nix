{
  lib,
  stdenvNoCC,
  fetchzip,
  nix-update-script,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "opencloud-web-pastebin";
  version = "2.1.0";

  src = fetchzip {
    url = "https://github.com/opencloud-eu/web-extensions/releases/download/pastebin-v${finalAttrs.version}/pastebin-${finalAttrs.version}.zip";
    hash = "sha256-o1ErQWjqLlEpfO1BrfSCtUJxr8so1bHd4hgh2v/jyOo=";
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
