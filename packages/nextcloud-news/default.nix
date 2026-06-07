{
  lib,
  stdenvNoCC,
  fetchurl,
  nix-update-script,
}:

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "nextcloud-news";
  version = "28.5.1";

  src = fetchurl {
    url = "https://github.com/nextcloud/news/releases/download/${finalAttrs.version}/news.tar.gz";
    hash = "sha256-T3UBQcNxte18J/yyIucGb/X105t3lh97KWn0joTTuDw=";
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
      "https://github.com/nextcloud/news"
      "--use-github-releases"
      "--version-regex"
      "v?(.*)$"
    ];
  };

  meta = {
    homepage = "https://github.com/nextcloud/news";
    description = "RSS/Atom feed reader for Nextcloud";
    license = lib.licenses.agpl3Plus;
  };
})
