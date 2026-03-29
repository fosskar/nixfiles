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
  alsa-plugins,
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
  libx11,
  libxcursor,
  libxrandr,
  libxi,
  libxcb,
  # misc
  dbus,
  openssl,
  sqlite,
  # gstreamer for audio
  gst_all_1,
  # wayland layer shell
  gtk-layer-shell,
  # feature flags
  enableGpu ? true,
}:
let
  pname = "voquill";
  version = "0.0.534";

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
    alsa-plugins
    pipewire
    libpulseaudio
    # input
    libxkbcommon
    xdotool
    # x11
    libx11
    libxcursor
    libxrandr
    libxi
    libxcb
    # misc
    dbus
    openssl
    sqlite
    gtk-layer-shell
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
    url = "https://github.com/josiahsrc/voquill/releases/download/desktop-v${version}/voquill-desktop_${version}_amd64.deb";
    hash = "sha256-VXbpmjpTFNCNGG0Na7sCz/AHOaAzYX9FislIOsV9kco=";
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

    # rename binary to voquill
    mv $out/bin/voquill-desktop $out/bin/voquill

    # fix desktop file
    if [ -d "$out/share/applications" ]; then
      for f in $out/share/applications/*.desktop; do
        substituteInPlace "$f" \
          --replace-quiet "Exec=voquill-desktop" "Exec=voquill" \
          --replace-quiet "Exec=/usr/bin/voquill-desktop" "Exec=voquill" || true
      done
    fi

    runHook postInstall
  '';

  # runtime library path
  postFixup = ''
    wrapProgram $out/bin/voquill \
      --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath runtimeDeps}" \
      --set ALSA_PLUGIN_DIR "${alsa-plugins}/lib/alsa-lib"
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
