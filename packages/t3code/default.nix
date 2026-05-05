{
  lib,
  appimageTools,
  fetchurl,
  makeWrapper,
  nix-update-script,
}:
let
  pname = "t3code";
  version = "0.0.22";

  src = fetchurl {
    url = "https://github.com/pingdotgg/t3code/releases/download/v${version}/T3-Code-${version}-x86_64.AppImage";
    hash = "sha256-JUlF9G6KkvOy550HwndsnfYQBUlReRWCJUe6cqx/9Xc=";
  };

  appimageContents = appimageTools.extractType2 { inherit pname version src; };
in
appimageTools.wrapType2 {
  inherit pname version src;
  nativeBuildInputs = [ makeWrapper ];

  extraInstallCommands = ''
    install -Dm444 ${appimageContents}/t3code.desktop $out/share/applications/t3code.desktop
    substituteInPlace $out/share/applications/t3code.desktop \
      --replace-quiet "Exec=AppRun --no-sandbox %U" "Exec=t3code" \
      --replace-quiet "Exec=AppRun" "Exec=t3code"
    cp -r ${appimageContents}/usr/share/icons $out/share/icons 2>/dev/null || true
    install -Dm444 ${appimageContents}/t3code.png $out/share/icons/hicolor/1024x1024/apps/t3code.png 2>/dev/null || true

    wrapProgram $out/bin/t3code \
      --add-flags "--ozone-platform-hint=auto" \
      --add-flags "--enable-features=WaylandWindowDecorations,UseOzonePlatform" \
      --add-flags "--enable-wayland-ime"
  '';

  passthru.updateScript = nix-update-script {
    extraArgs = [
      "--url"
      "https://github.com/pingdotgg/t3code"
      "--use-github-releases"
    ];
  };

  meta = {
    description = "minimal web GUI for coding agents";
    homepage = "https://github.com/pingdotgg/t3code";
    license = lib.licenses.unfree;
    maintainers = [ ];
    platforms = [ "x86_64-linux" ];
    mainProgram = "t3code";
  };
}
