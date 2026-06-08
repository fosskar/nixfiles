{
  lib,
  stdenv,
  fetchFromGitHub,
  meson,
  ninja,
  pkg-config,
  wayland-scanner,
  makeWrapper,
  wayland,
  wayland-protocols,
  libxkbcommon,
  freetype,
  fontconfig,
  cairo,
  pango,
  librsvg,
  glib,
  libGL,
  libwebp,
  # runtime deps for the session wrapper
  cage,
  wlr-randr,
  dbus,
}:
stdenv.mkDerivation (_finalAttrs: {
  pname = "noctalia-greeter";
  version = "0-unstable-2026-06-08";

  src = fetchFromGitHub {
    owner = "noctalia-dev";
    repo = "noctalia-greeter";
    rev = "367ab83dcd9190010f093cfe0e123ba132a75b5a";
    hash = "sha256-/jQ/lkgjaH5EOTZRXk4YZaFrjrKhq/fzZsU6nm7wPt0=";
  };

  nativeBuildInputs = [
    meson
    ninja
    pkg-config
    wayland-scanner
    makeWrapper
  ];

  buildInputs = [
    wayland
    wayland-protocols
    libxkbcommon
    freetype
    fontconfig
    cairo
    pango
    librsvg
    glib
    libGL
    libwebp
  ];

  # plain buildtype avoids the project's release -march=native (non-reproducible)
  mesonBuildType = "plain";

  # upstream ships a relative exec.path; polkit needs the absolute binary path
  # so noctalia-shell's pkexec sync authorizes against this action.
  postInstall = ''
    substituteInPlace $out/share/polkit-1/actions/org.noctalia.greeter.apply-appearance.policy \
      --replace-fail '>noctalia-greeter-apply-appearance<' \
      '>${placeholder "out"}/bin/noctalia-greeter-apply-appearance<'
  '';

  postFixup = ''
    wrapProgram $out/bin/noctalia-greeter-session \
      --prefix PATH : ${
        lib.makeBinPath [
          cage
          wlr-randr
          dbus
        ]
      }
  '';

  meta = {
    description = "Minimal login greeter for greetd matching Noctalia Shell";
    homepage = "https://github.com/noctalia-dev/noctalia-greeter";
    license = lib.licenses.mit;
    mainProgram = "noctalia-greeter";
    platforms = lib.platforms.linux;
  };
})
