{
  lib,
  stdenvNoCC,
  fetchurl,
  nix-update-script,
}:

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "nextcloud-assistant";
  version = "3.4.3";

  src = fetchurl {
    url = "https://github.com/nextcloud-releases/assistant/releases/download/v${finalAttrs.version}/assistant-v${finalAttrs.version}.tar.gz";
    hash = "sha256-dTOft/FEgkkdPl/Fp7DzSUqKReQwQR/+LDN3vqIHcME=";
  };

  installPhase = ''
    runHook preInstall

    if [ ! -f ./appinfo/info.xml ]; then
      echo "appinfo/info.xml doesn't exist in $out, aborting!"
      exit 1
    fi

    cp -r . $out

    runHook postInstall
  '';

  passthru.updateScript = nix-update-script {
    extraArgs = [
      "--url"
      "https://github.com/nextcloud-releases/assistant"
      "--use-github-releases"
      "--version-regex"
      "v?(.*)$"
    ];
  };

  meta = {
    homepage = "https://github.com/nextcloud/assistant";
    description = "Nextcloud Assistant app";
    license = lib.licenses.agpl3Plus;
  };
})
