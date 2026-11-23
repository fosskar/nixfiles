{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
  fetchPnpmDeps,
  pnpm_10,
  pnpmConfigHook,
  nodejs,
  python3,
  makeBinaryWrapper,
  chromaprint,
  ffmpeg,
  loudgain,
  nix-update-script,
}:
let
  pname = "droppedneedle";
  version = "3.1.0";

  src = fetchFromGitHub {
    owner = "DroppedNeedle";
    repo = "DroppedNeedle";
    tag = "v${version}";
    hash = "sha256-dgL8w8P6e2hcpWUMGHwM8k+HCJhzETiSFVM53YDSoNU=";
  };

  frontend = stdenvNoCC.mkDerivation (finalAttrs: {
    pname = "${pname}-frontend";
    inherit version src;
    sourceRoot = "${src.name}/frontend";

    pnpmDeps = fetchPnpmDeps {
      inherit (finalAttrs) pname version src;
      sourceRoot = "${src.name}/frontend";
      pnpm = pnpm_10;
      fetcherVersion = 3;
      hash = "sha256-VCC8/D948fx+cgaIMhX/M7etOysAWXEFa/wKJ/TXNbE=";
    };

    nativeBuildInputs = [
      nodejs
      pnpm_10
      pnpmConfigHook
    ];

    buildPhase = ''
      runHook preBuild
      pnpm run build
      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall
      cp -r build $out
      runHook postInstall
    '';
  });

  python = python3.withPackages (
    packages:
    [
      packages.aiofiles
      packages.bcrypt
      packages.cryptography
      packages.fastapi
      packages.h2
      packages.httpx
      packages.msgspec
      packages.mutagen
      packages.packaging
      packages.pillow
      packages.pydantic
      packages.pydantic-settings
      packages.python-dotenv
      packages.python-multipart
      packages.rapidfuzz
      packages.starlette
      packages.unidecode
      packages.uvicorn
    ]
    ++ packages.httpx.optional-dependencies.http2
    ++ packages.uvicorn.optional-dependencies.standard
  );
in
stdenvNoCC.mkDerivation {
  inherit pname version src;

  nativeBuildInputs = [ makeBinaryWrapper ];

  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/droppedneedle/frontend
    cp -r backend $out/share/droppedneedle/backend
    rm -r $out/share/droppedneedle/backend/tests
    ln -s ${frontend} $out/share/droppedneedle/frontend/build

    makeWrapper ${lib.getExe python} $out/bin/droppedneedle \
      --prefix PYTHONPATH : $out/share/droppedneedle/backend \
      --prefix PATH : ${
        lib.makeBinPath [
          chromaprint
          ffmpeg
          loudgain
        ]
      } \
      --add-flags "-m maintenance.automatic_upgrade --start-target"

    runHook postInstall
  '';

  passthru = {
    inherit frontend;
    updateScript = nix-update-script {
      extraArgs = [
        "--subpackage"
        "frontend"
      ];
    };
  };

  meta = {
    description = "Self-hosted music request and library engine";
    homepage = "https://droppedneedle.com";
    license = lib.licenses.agpl3Only;
    mainProgram = "droppedneedle";
    platforms = lib.platforms.linux;
  };
}
