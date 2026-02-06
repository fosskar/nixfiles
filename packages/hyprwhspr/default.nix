{
  lib,
  python3Packages,
  fetchFromGitHub,
  makeWrapper,
  # runtime deps
  gobject-introspection,
  gtk3,
  wl-clipboard,
  wtype,
  libnotify,
  # custom packages
  pywhispercpp,
}:
let
  python = python3Packages.python.withPackages (ps: [
    # audio
    ps.sounddevice
    ps.numpy
    ps.scipy
    # input/clipboard
    ps.evdev
    ps.pyperclip
    # speech recognition
    pywhispercpp
    ps.requests
    ps.websocket-client
    # system
    ps.psutil
    ps.pyudev
    ps.pulsectl
    ps.dbus-python
    # ui
    ps.rich
    ps.pygobject3
  ]);
in
python3Packages.buildPythonApplication rec {
  pname = "hyprwhspr";
  version = "1.18.14";
  format = "other"; # no setup.py, custom install

  src = fetchFromGitHub {
    owner = "goodroot";
    repo = "hyprwhspr";
    tag = "v${version}";
    hash = "sha256-peo/GRLZ9wSQ0/MX5hFQhv+MBfDHquIjTgKIJNu6te0=";
  };

  nativeBuildInputs = [
    makeWrapper
    gobject-introspection
  ];

  buildInputs = [
    gtk3
  ];

  dontBuild = true;

  installPhase = ''
    runHook preInstall

    # install python lib
    mkdir -p $out/lib/hyprwhspr
    cp -r lib/* $out/lib/hyprwhspr/

    # install config
    mkdir -p $out/share/hyprwhspr
    cp -r config/* $out/share/hyprwhspr/

    # install launcher
    mkdir -p $out/bin
    cat > $out/bin/hyprwhspr << 'EOF'
    #!/usr/bin/env bash
    export PYTHONPATH="@out@/lib/hyprwhspr:$PYTHONPATH"
    exec @python@/bin/python @out@/lib/hyprwhspr/main.py "$@"
    EOF
    chmod +x $out/bin/hyprwhspr
    substituteInPlace $out/bin/hyprwhspr \
      --replace-fail "@out@" "$out" \
      --replace-fail "@python@" "${python}"

    runHook postInstall
  '';

  postFixup = ''
    wrapProgram $out/bin/hyprwhspr \
      --prefix PATH : ${
        lib.makeBinPath [
          wl-clipboard
          wtype
          libnotify
        ]
      } \
      --set GI_TYPELIB_PATH "${gtk3}/lib/girepository-1.0"
  '';

  meta = {
    description = "Native speech-to-text for Hyprland/Wayland using whisper.cpp";
    homepage = "https://github.com/goodroot/hyprwhspr";
    license = lib.licenses.mit;
    maintainers = [ ];
    platforms = lib.platforms.linux;
    mainProgram = "hyprwhspr";
  };
}
