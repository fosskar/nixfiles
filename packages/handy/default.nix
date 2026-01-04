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
  # gstreamer for audio feedback
  gst_all_1,
  # input (wayland)
  wtype,
  dotool,
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
  # feature flags
  enableGpu ? true,
}:
let
  pname = "handy";
  version = "0.6.10";

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
    # gstreamer
    gst_all_1.gstreamer
    gst_all_1.gst-plugins-base
    gst_all_1.gst-plugins-good
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
  ]
  ++ lib.optionals enableGpu [
    vulkan-loader
    libGL
  ];
in
stdenv.mkDerivation {
  inherit pname version;

  src = fetchurl {
    url = "https://github.com/cjpais/Handy/releases/download/v${version}/Handy_${version}_amd64.deb";
    hash = "sha256-mHKbcVJnshAdQT6I4Y7kxMsq5jUfZosBGe107Aaoy3I=";
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

    # rename to lowercase if needed
    if [ -f "$out/bin/Handy" ]; then
      mv $out/bin/Handy $out/bin/handy
    fi

    # fix desktop file
    if [ -d "$out/share/applications" ]; then
      for f in $out/share/applications/*.desktop; do
        substituteInPlace "$f" \
          --replace-quiet "Exec=Handy" "Exec=handy" \
          --replace-quiet "Exec=/usr/bin/handy" "Exec=handy" || true
      done
    fi

    runHook postInstall
  '';

  postFixup = ''
    wrapProgram $out/bin/handy \
      --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath runtimeDeps}" \
      --prefix PATH : "${
        lib.makeBinPath [
          wtype
          dotool
          xdotool
        ]
      }" \
      --prefix GST_PLUGIN_PATH : "${gst_all_1.gst-plugins-base}/lib/gstreamer-1.0" \
      --prefix GST_PLUGIN_PATH : "${gst_all_1.gst-plugins-good}/lib/gstreamer-1.0"
  '';

  meta = {
    description = "Open source speech-to-text with Whisper and Parakeet";
    homepage = "https://github.com/cjpais/Handy";
    license = lib.licenses.agpl3Only;
    maintainers = [ ];
    platforms = [ "x86_64-linux" ];
    mainProgram = "handy";
  };
}
