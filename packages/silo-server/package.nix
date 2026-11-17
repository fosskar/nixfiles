{
  lib,
  buildGo127Module,
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
  version = "0-unstable-2026-11-17";
  rev = "217ff25abc5b9d0d3dc359de63349b7dc3d1d2eb";

  src = fetchFromGitHub {
    owner = "Silo-Server";
    repo = "silo-server";
    inherit rev;
    hash = "sha256-ZzhBVJYiQYdnyIe/7hUOX7vlBZIgpC3tnR7wNniVutM=";
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
buildGo127Module {
  pname = "silo-server";
  inherit version src;

  vendorHash = "sha256-wr1ekqSK1V2KUj4P7Yr3coxk4R2ikxHp79a3ALDfo+4=";

  nativeBuildInputs = [
    makeWrapper
    pkg-config
  ];
  buildInputs = [ vips ];

  subPackages = [ "cmd/silo" ];

  # upstream requires go 1.27.4; nixpkgs has 1.27.3
  postPatch = ''
    substituteInPlace go.mod --replace-fail 'go 1.27.4' 'go 1.27.3'
  '';

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
