{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  makeWrapper,
  git,
  nix-update-script,
}:
let
  pname = "druk";
  version = "1.21.1";
in
stdenv.mkDerivation {
  inherit pname version;

  src = fetchurl {
    url = "https://github.com/letstri/druk/releases/download/v${version}/druk-linux-x64.tar.gz";
    hash = "sha256-bNkYU0jnitnpwROdUvqa84EtSvd/4gdBWs5NnZ6+ZF0=";
  };

  sourceRoot = ".";

  # bun single-file executable: stripping mangles the appended payload and the
  # binary then reports a stale embedded version
  dontStrip = true;

  nativeBuildInputs = [
    autoPatchelfHook
    makeWrapper
  ];

  installPhase = ''
    runHook preInstall

    install -Dm755 druk $out/bin/druk
    install -Dm444 THIRD_PARTY_NOTICES.md -t $out/share/doc/druk
    install -Dm444 PDFIUM_LICENSE -t $out/share/doc/druk

    runHook postInstall
  '';

  postFixup = ''
    wrapProgram $out/bin/druk --prefix PATH : "${lib.makeBinPath [ git ]}"
  '';

  passthru.updateScript = nix-update-script {
    extraArgs = [
      "--url"
      "https://github.com/letstri/druk"
      "--use-github-releases"
    ];
  };

  meta = {
    description = "terminal code editor with file tree, tabs, search, git marks and syntax highlighting";
    homepage = "https://github.com/letstri/druk";
    license = lib.licenses.mit;
    platforms = [ "x86_64-linux" ];
    mainProgram = "druk";
  };
}
