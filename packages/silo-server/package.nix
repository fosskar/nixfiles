{
  lib,
  buildGo126Module,
  fetchFromGitHub,
  fetchPnpmDeps,
  jellyfin-ffmpeg,
  makeWrapper,
  nix-update-script,
  nodejs_24,
  pkg-config,
  pnpm_10,
  pnpmConfigHook,
  stdenvNoCC,
  vips,
}:
let
  # upstream has no tags or releases yet
  version = "0-unstable-2026-11-15";
  rev = "c11b0a968f0d5980b7005579fb95acc2d11d8321";

  src = fetchFromGitHub {
    owner = "Silo-Server";
    repo = "silo-server";
    inherit rev;
    hash = "sha256-6DTUP0HpSEvvq70FrAJtUS3SoCmteOCZtSt7GFn2Ob0=";
  };

  frontend = stdenvNoCC.mkDerivation (finalAttrs: {
    pname = "silo-server-frontend";
    inherit version src;
    sourceRoot = "${src.name}/web";

    pnpmDeps = fetchPnpmDeps {
      inherit (finalAttrs)
        pname
        version
        src
        sourceRoot
        ;
      pnpm = pnpm_10;
      fetcherVersion = 5;
      hash = "sha256-6FCFdtQt0zR2Dalyg+fMLUjXPplPxHXHjePxISMYVh4=";
    };

    nativeBuildInputs = [
      nodejs_24
      pnpm_10
      pnpmConfigHook
    ];

    # `pnpm run build` typechecks first with tsrs, a prebuilt binary that does
    # not run on nixos
    buildPhase = ''
      runHook preBuild
      pnpm exec vite build
      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall
      cp -r dist $out
      runHook postInstall
    '';
  });
in
buildGo126Module {
  pname = "silo-server";
  inherit version src;

  vendorHash = "sha256-h3K5uEOEfD5/FRrwm2dqRBhrRLT1cQWljmI+KyV5QYY=";

  nativeBuildInputs = [
    makeWrapper
    pkg-config
  ];
  buildInputs = [ vips ];

  subPackages = [ "cmd/silo" ];

  # web/embed.go embeds web/dist
  preBuild = ''
    cp -r ${frontend} web/dist
  '';

  ldflags = [
    "-s"
    "-w"
    "-X github.com/Silo-Server/silo-server/internal/buildinfo.revisionOverride=${rev}"
  ];

  # the tests need postgres and redis
  doCheck = false;

  # ffmpeg and ffprobe are looked up on PATH
  postInstall = ''
    wrapProgram $out/bin/silo --suffix PATH : ${lib.makeBinPath [ jellyfin-ffmpeg ]}
  '';

  passthru = {
    inherit frontend;
    updateScript = nix-update-script {
      extraArgs = [
        "--version=branch"
        "--subpackage"
        "frontend"
      ];
    };
  };

  meta = {
    description = "Self-hosted media server with requests and Jellyfin-compatible APIs";
    homepage = "https://github.com/Silo-Server/silo-server";
    license = lib.licenses.agpl3Plus;
    mainProgram = "silo";
  };
}
