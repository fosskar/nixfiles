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
  wlroots_0_20,
  # runtime deps for the session wrapper
  dbus,
}:
stdenv.mkDerivation (_finalAttrs: {
  pname = "noctalia-greeter";
  version = "0-unstable-2026-06-10";

  src = fetchFromGitHub {
    owner = "noctalia-dev";
    repo = "noctalia-greeter";
    rev = "11f8092eda1f2a674a2e7ee25a8325b41f894e39";
    hash = "sha256-sRnrTFTul+wZoxSG2nynLamUPRAQki9pccDr11okEjI=";
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
    wlroots_0_20
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
      --prefix PATH : ${lib.makeBinPath [ dbus ]}
  '';

  meta = {
    description = "Minimal login greeter for greetd matching Noctalia Shell";
    homepage = "https://github.com/noctalia-dev/noctalia-greeter";
    license = lib.licenses.mit;
    mainProgram = "noctalia-greeter";
    platforms = lib.platforms.linux;
  };
})
