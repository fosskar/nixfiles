{
  lib,
  buildGo127Module,
  fetchFromGitHub,
  fetchurl,
  go_1_27,
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
  version = "0-unstable-2026-11-24";
  rev = "64f9ee20eceef0c79d176ee35732f51b4153a944";

  src = fetchFromGitHub {
    owner = "Silo-Server";
    repo = "silo-server";
    inherit rev;
    hash = "sha256-JS0R9PI05Xc6jZ6zui8XokCtTnNhB0bUS83aODhO6y4=";
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
      hash = "sha256-eKpAp8zH6CnMCpGfvc0pPprlkrI3dgHPv+itPyurPKk=";
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

  # upstream and its shunpike module require go 1.27.4; nixpkgs has it in
  # staging. drop once go_1_27 reaches 1.27.4
  # https://redirect.github.com/NixOS/nixpkgs/pull/586269
  go = go_1_27.overrideAttrs (
    finalAttrs: _: {
      version = "1.27.4";
      src = fetchurl {
        url = "https://go.dev/dl/go${finalAttrs.version}.src.tar.gz";
        hash = "sha256-c8+4VxrsDAEXdofbhxY9Rqog6XeWcncokaoXZU2aYJk=";
      };
    }
  );
in
(buildGo127Module.override { inherit go; }) {
  pname = "silo-server";
  inherit version src;

  vendorHash = "sha256-MLe6C+BzDv089H8DX8tdR+udcZ4JhWQ6wU6FQgB9Ikk=";

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
