{
  lib,
  appimageTools,
  fetchurl,
  makeWrapper,
}:
let
  pname = "t3code";
  version = "0.0.13";

  src = fetchurl {
    url = "https://github.com/pingdotgg/t3code/releases/download/v${version}/T3-Code-${version}-x86_64.AppImage";
    hash = "sha256-oHKIh+aHsbGVHEoLLjItl6AbVRwvWVlZaIWyHKiekVc=";
  };

  extracted = appimageTools.extractType2 { inherit pname version src; };
in
appimageTools.wrapAppImage {
  inherit pname version;
  src = extracted;
  nativeBuildInputs = [ makeWrapper ];

  extraInstallCommands = ''
    install -Dm444 ${extracted}/t3-code-desktop.desktop $out/share/applications/t3code.desktop
    substituteInPlace $out/share/applications/t3code.desktop \
      --replace-quiet "Exec=AppRun" "Exec=t3code"
    cp -r ${extracted}/usr/share/icons $out/share/icons 2>/dev/null || true
    install -Dm444 ${extracted}/t3-code-desktop.png $out/share/icons/hicolor/256x256/apps/t3-code-desktop.png 2>/dev/null || true

    wrapProgram $out/bin/t3code \
      --add-flags "--ozone-platform-hint=auto" \
      --add-flags "--enable-features=WaylandWindowDecorations,UseOzonePlatform" \
      --add-flags "--enable-wayland-ime"
  '';

  meta = {
    description = "minimal web GUI for coding agents";
    homepage = "https://github.com/pingdotgg/t3code";
    license = lib.licenses.unfree;
    maintainers = [ ];
    platforms = [ "x86_64-linux" ];
    mainProgram = "t3code";
  };
}
