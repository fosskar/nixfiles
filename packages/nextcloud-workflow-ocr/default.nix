{
  lib,
  stdenvNoCC,
  fetchurl,
  nix-update-script,
}:

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "nextcloud-workflow-ocr";
  version = "1.33.1";

  src = fetchurl {
    url = "https://github.com/R0Wi-DEV/workflow_ocr/releases/download/v${finalAttrs.version}/workflow_ocr.tar.gz";
    sha512 = "2gjf3w7qysm0ab059v6xygcwdbp5riwpq4yhmrjva1r57748a52szkzmh48g859lb79n02g1y9i124jqayvlb3yfzq1xg5ssyw9bmnj";
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
      "https://github.com/R0Wi-DEV/workflow_ocr"
      "--use-github-releases"
      "--version-regex"
      "v?(.*)$"
    ];
  };

  meta = {
    homepage = "https://github.com/R0Wi-DEV/workflow_ocr";
    description = "OCR workflow provider for Nextcloud";
    license = lib.licenses.agpl3Plus;
  };
})
