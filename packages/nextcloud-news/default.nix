{
  lib,
  stdenvNoCC,
  fetchurl,
  nix-update-script,
}:

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "nextcloud-news";
  version = "28.0.0-rc.2";

  src = fetchurl {
    url = "https://github.com/nextcloud/news/releases/download/${finalAttrs.version}/news.tar.gz";
    hash = "sha512-LAtJaLyXVa3uXowyTNqh/F9FAJPaFU8cTAgcEKQqFlywu4LNUykQqsQtCkeiqZ5xui2lrzF9nWQepRGSA5kh6A==";
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
