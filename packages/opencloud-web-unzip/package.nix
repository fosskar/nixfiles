{
  lib,
  stdenvNoCC,
  fetchzip,
  nix-update-script,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "opencloud-web-unzip";
  version = "2.2.0";

  src = fetchzip {
    url = "https://github.com/opencloud-eu/web-extensions/releases/download/unzip-v${finalAttrs.version}/unzip-${finalAttrs.version}.zip";
    hash = "sha256-xAUKQSSVN+LdO+QX/2mU8kmUn4fcjNQhB0HB9Gi0V3Q=";
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
