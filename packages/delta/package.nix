{
  lib,
  stdenvNoCC,
  requireFile,
  runtimeShell,
  xkeyboard_config,
  wayland,
  libxkbcommon,
  vulkan-loader,
  libglvnd,
  fontconfig,
  freetype,
  alsa-lib,
  libgbm,
  libx11,
  libxcb,
  libxcursor,
  libxi,
  libxrandr,
}:
let
  pname = "delta";
  version = "0.1.1-nightly.20260820.13";

  src = requireFile {
    name = "delta-linux-x86_64.tar.gz";
    hash = "sha256-v8daBywEBtvj379BHpYCCh0klR+n76hW/xAZ9SLY8LQ=";
    message = ''
      Download the x86_64 Linux archive from https://delta.dev/download and add it with:
        nix store add-file delta-linux-x86_64.tar.gz
    '';
  };

  runtimeLibraries = [
    wayland
    libxkbcommon
    vulkan-loader
    libglvnd
    fontconfig
    freetype
    alsa-lib
    libgbm
    libx11
    libxcb
    libxcursor
    libxi
    libxrandr
  ];
in
stdenvNoCC.mkDerivation {
  inherit pname version src;

  sourceRoot = "Delta";

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin $out/share/delta-seed $out/share/applications $out/share/icons
    cp -a bin lib share/icons $out/share/delta-seed/
    cp -a share/icons/. $out/share/icons/
    cp share/applications/dev.zed.Delta.desktop $out/share/applications/

    substituteInPlace $out/share/applications/dev.zed.Delta.desktop \
      --replace-fail "Exec=delta " "Exec=delta-app "

    cat > $out/bin/delta-app <<EOF
    #!${runtimeShell}
    set -eu

    app_dir="\$HOME/.local/delta.app"
    if [ ! -x "\$app_dir/bin/delta" ]; then
      staging="\$HOME/.local/.delta.app.installing"
      rm -rf "\$staging"
      mkdir -p "\$staging"
      cp -a "$out/share/delta-seed/." "\$staging/"
      chmod -R u+w "\$staging"
      mkdir -p "\$HOME/.local"
      mv "\$staging" "\$app_dir"
    fi

    export XKB_CONFIG_ROOT="${xkeyboard_config}/etc/X11/xkb"
    export LD_LIBRARY_PATH="\$app_dir/lib:${lib.makeLibraryPath runtimeLibraries}"
    exec "\$app_dir/bin/delta" "\$@"
    EOF
    chmod +x $out/bin/delta-app

    runHook postInstall
  '';

  meta = {
    description = "Collaborative agent workspace by the creators of Zed";
    homepage = "https://delta.dev";
    license = lib.licenses.unfree;
    mainProgram = "delta-app";
    platforms = [ "x86_64-linux" ];
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
}
