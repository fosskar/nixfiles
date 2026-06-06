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
    hash = "sha512-0taVuNe6vB7wd34sur3CkogQkw9PAJvOoqmghwisf34tikLknJKD2jJX6Am+POZyV+Ps+W52KmApULXHhw8nnw==";
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
