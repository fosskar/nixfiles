{
  lib,
  stdenv,
  fetchurl,
  nix-update-script,
}:
let
  pname = "liwan";
  version = "1.8.2";
in
stdenv.mkDerivation {
  inherit pname version;

  # upstream's static musl build; the source build needs rust, bun and a
  # bundled duckdb
  src = fetchurl {
    url = "https://github.com/explodingcamera/liwan/releases/download/liwan-v${version}/liwan-x86_64-unknown-linux-musl.tar.gz";
    hash = "sha256-aeYwQi7yI35YE+Uy43LLhf/2rhgz8VK0uyJnZP9PiPg=";
  };

  sourceRoot = ".";

  installPhase = ''
    runHook preInstall

    install -Dm755 liwan $out/bin/liwan

    runHook postInstall
  '';

  passthru.updateScript = nix-update-script {
    extraArgs = [
      "--url"
      "https://github.com/explodingcamera/liwan"
      "--use-github-releases"
      "--version-regex"
      "liwan-v(.*)"
    ];
  };

  meta = {
    description = "lightweight web analytics with a built-in dashboard and embedded database";
    homepage = "https://liwan.dev";
    license = lib.licenses.asl20;
    platforms = [ "x86_64-linux" ];
    mainProgram = "liwan";
  };
}
