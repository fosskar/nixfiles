{
  lib,
  stdenv,
  fetchFromGitHub,
  go,
}:
stdenv.mkDerivation {
  pname = "niri-focus-or-spawn";
  version = "0-unstable-2026-05-30";

  src = fetchFromGitHub {
    owner = "piv-pav";
    repo = "niri-focus-or-spawn";
    rev = "38231fd88bee207d2840c4cc9e85cdae14b0138f";
    hash = "sha256-xYfuLSRLtFoJ2nALDUruo6pfCUKvbQs5hSFCUMdK4AA=";
  };

  nativeBuildInputs = [ go ];

  # upstream is a single go file without a go.mod; build it standalone
  buildPhase = ''
    runHook preBuild
    export HOME=$TMPDIR GOCACHE=$TMPDIR/go-cache
    CGO_ENABLED=0 go build -trimpath -ldflags "-s -w" -o focus-or-spawn focus-or-spawn.go
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    install -Dm755 focus-or-spawn $out/bin/focus-or-spawn
    runHook postInstall
  '';

  meta = {
    description = "focus a niri window by exact app-id, or spawn the command and focus the new window";
    homepage = "https://github.com/piv-pav/niri-focus-or-spawn";
    license = lib.licenses.publicDomain;
    mainProgram = "focus-or-spawn";
    platforms = lib.platforms.linux;
  };
}
