{
  lib,
  stdenvNoCC,
  requireFile,
  writeShellScript,
  makeDesktopItem,
  copyDesktopItems,
}:
let
  pname = "tern";
  version = "0.9.7";
  # the launcher seeds a writable copy in $HOME, which tern then updates in place; runtime libraries come from nix-ld
  launcher = writeShellScript "tern" ''
    bin="$HOME/.local/opt/tern/tern"
    if [ ! -x "$bin" ]; then
      install -Dm755 @out@/libexec/tern/tern "$bin"
    fi
    exec "$bin" "$@"
  '';
in
stdenvNoCC.mkDerivation {
  inherit pname version;

  # invite-only download; add it with: nix-store --add-fixed sha256 Tern-<version>-linux-x86_64.tar.gz
  src = requireFile {
    name = "Tern-${version}-linux-x86_64.tar.gz";
    url = "https://build.stencil.so/tern";
    hash = "sha256-DPKeJdibqTNIy/YsryEX6AbCSR+RNAt+sfxo2AqE5jg=";
  };

  sourceRoot = ".";

  nativeBuildInputs = [ copyDesktopItems ];

  desktopItems = [
    (makeDesktopItem {
      name = "tern";
      desktopName = "Tern";
      comment = "a multiplexing terminal";
      exec = "tern";
      icon = "utilities-terminal";
      categories = [
        "System"
        "TerminalEmulator"
      ];
    })
  ];

  installPhase = ''
    runHook preInstall

    install -Dm755 tern/tern $out/libexec/tern/tern
    install -Dm755 ${launcher} $out/bin/tern
    substituteInPlace $out/bin/tern --replace-fail @out@ $out

    runHook postInstall
  '';

  meta = {
    description = "multiplexing terminal by Stencil";
    homepage = "https://stencil.so/tern";
    license = lib.licenses.unfree;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    platforms = [ "x86_64-linux" ];
    # source is not downloadable, so ci skips the package check
    hydraPlatforms = [ ];
    mainProgram = "tern";
  };
}
