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
    sha512 = "3l23683j88sa7k4kmyk3bx55nx737m9l93hlbf4m882jlydhaxv0p0n5aj107089hf4y5fsjc04apzwl7d4qclcbvpasmcppil4j2rc";
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
