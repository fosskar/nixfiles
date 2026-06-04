{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  nix-update-script,
}:
stdenv.mkDerivation rec {
  pname = "kittylitter";
  version = "0.3.4";

  # prebuilt binary from cargo-dist github releases
  src = fetchurl {
    url = "https://github.com/dnakov/litter/releases/download/v${version}/kittylitter-x86_64-unknown-linux-gnu.tar.xz";
    hash = "sha256-TlshPfLzr8LB3apPEKWAQ6v/uWgYMFAEx/vjTxZNibA=";
  };

  sourceRoot = ".";

  nativeBuildInputs = [ autoPatchelfHook ];
  buildInputs = [ stdenv.cc.cc.lib ];

  installPhase = ''
    runHook preInstall
    install -Dm755 */kittylitter $out/bin/kittylitter
    runHook postInstall
  '';

  passthru.updateScript = nix-update-script {
    extraArgs = [
      "--url"
      "https://github.com/dnakov/litter"
      "--use-github-releases"
      "--version-regex"
      ''^v(\d+\.\d+\.\d+)$''
    ];
  };

  meta = {
    description = "Iroh-backed daemon that multiplexes local coding agents (Codex, Pi, OpenCode, Claude) for paired clients";
    homepage = "https://github.com/dnakov/litter";
    license = lib.licenses.gpl3Only;
    maintainers = [ ];
    platforms = [ "x86_64-linux" ];
    mainProgram = "kittylitter";
  };
}
