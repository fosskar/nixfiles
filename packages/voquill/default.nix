{
  lib,
  stdenv,
  fetchurl,
  wrapGAppsHook3,
  autoPatchelfHook,
  # tauri/webkit deps
  gtk3,
  webkitgtk_4_1,
  libayatana-appindicator,
  librsvg,
  glib,
  glib-networking,
  libsoup_3,
  # audio
  alsa-lib,
  pipewire,
  libpulseaudio,
  # input
  libxkbcommon,
  xdotool,
  # vulkan for GPU whisper
  vulkan-loader,
  # opengl
  libGL,
  # x11
  xorg,
  # misc
  dbus,
  openssl,
  sqlite,
  # gstreamer for audio
  gst_all_1,
  # feature flags
  enableGpu ? true,
}:
let
  pname = "voquill";
  version = "0.0.203";

  runtimeDeps = [
    # tauri/webkit runtime deps
    gtk3
    webkitgtk_4_1
    libayatana-appindicator
    librsvg
    glib
    glib-networking
    libsoup_3
    # audio
    alsa-lib
    pipewire
    libpulseaudio
    # input
    libxkbcommon
    xdotool
    # x11
    xorg.libX11
    xorg.libXcursor
    xorg.libXrandr
    xorg.libXi
    xorg.libxcb
    # misc
    dbus
    openssl
    sqlite
    # gstreamer
    gst_all_1.gstreamer
    gst_all_1.gst-plugins-base
    gst_all_1.gst-plugins-good
    gst_all_1.gst-plugins-bad
  ]
  ++ lib.optionals enableGpu [
    vulkan-loader
    libGL
  ];
in
stdenv.mkDerivation {
  inherit pname version;

  # use pre-built binary from github releases
  src = fetchurl {
    url = "https://github.com/josiahsrc/voquill/releases/download/desktop-v${version}/Voquill_${version}_amd64.deb";
    hash = "sha256-Wx46SqlBsY9QLoMNRCQ+EJ1FmvKSvxk4GbraQUdIruw=";
  };

  nativeBuildInputs = [
    autoPatchelfHook
    wrapGAppsHook3
  ];

  buildInputs = runtimeDeps;

  unpackPhase = ''
    ar x $src
    tar xf data.tar.*
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out
    cp -r usr/* $out/

    # rename to lowercase
    if [ -f "$out/bin/Voquill" ]; then
      mv $out/bin/Voquill $out/bin/voquill
    fi
    if [ -f "$out/bin/voquill" ]; then
      :
    elif [ -f "$out/share/Voquill/voquill" ]; then
      mkdir -p $out/bin
      ln -s $out/share/Voquill/voquill $out/bin/voquill
    fi

    # fix desktop file
    if [ -d "$out/share/applications" ]; then
      for f in $out/share/applications/*.desktop; do
        substituteInPlace "$f" \
          --replace-quiet "Exec=Voquill" "Exec=voquill" \
          --replace-quiet "Exec=/usr/bin/voquill" "Exec=voquill" || true
      done
    fi

    runHook postInstall
  '';

  # runtime library path
  postFixup = ''
    wrapProgram $out/bin/voquill \
      --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath runtimeDeps}" \
      --set GDK_BACKEND x11 \
      --set RUST_BACKTRACE full \
      --set RUST_LOG debug \
      ${lib.optionalString enableGpu ''--set VK_ICD_FILENAMES "/run/opengl-driver/share/vulkan/icd.d/radeon_icd.x86_64.json"''}
  '';

  meta = {
    description = "AI voice dictation - open source Wispr Flow alternative";
    homepage = "https://github.com/josiahsrc/voquill";
    license = lib.licenses.agpl3Only;
    maintainers = [ ];
    platforms = [ "x86_64-linux" ];
    mainProgram = "voquill";
  };
}
