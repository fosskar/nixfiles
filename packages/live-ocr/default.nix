{
  lib,
  buildGoModule,
  pkg-config,
  vulkan-headers,
  libxkbcommon,
  wayland,
  wayland-protocols,
  libGL,
  egl-wayland,
  libx11,
  libxcursor,
  libxfixes,
  libxcb,
  libxxf86vm,
  tesseract,
  leptonica,
  wl-clipboard,
  grim,
  slurp,
  libnotify,
  makeWrapper,
}:
buildGoModule {
  pname = "live-ocr";
  version = "0.1.0";

  src = ./live-ocr;

  vendorHash = "sha256-r8cPbymYp53RuRTKoOfJa2q8Stv+B45birS0m2pLqyA=";

  nativeBuildInputs = [
    pkg-config
    makeWrapper
  ];

  buildInputs = [
    vulkan-headers
    libxkbcommon
    wayland
    wayland-protocols
    libGL
    egl-wayland
    libx11
    libxcursor
    libxfixes
    libxcb
    libxxf86vm
    tesseract
    leptonica
  ];

  postInstall = ''
    mkdir -p $out/share/icons/hicolor/scalable/apps
    cp ${./live-ocr/icon.svg} $out/share/icons/hicolor/scalable/apps/live-ocr.svg

    wrapProgram $out/bin/live-ocr \
      --prefix PATH : ${
        lib.makeBinPath [
          grim
          slurp
          wl-clipboard
          libnotify
        ]
      }
  '';

  meta = {
    description = "interactive OCR overlay for wayland";
    license = lib.licenses.mit;
    mainProgram = "live-ocr";
  };
}
