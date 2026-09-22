{
  lib,
  buildGoModule,
  buildNpmPackage,
  fetchFromGitHub,
  go-swag,
  makeWrapper,
  nix-update-script,
}:
let
  version = "0.13.0";

  src = fetchFromGitHub {
    owner = "Noooste";
    repo = "garage-ui";
    tag = "v${version}";
    hash = "sha256-YqMKQEcF2quv7ir7xWNfojM/ZMPsXwWyC6N5mStc/WE=";
  };

  frontend = buildNpmPackage {
    pname = "garage-ui-frontend";
    inherit version src;
    sourceRoot = "${src.name}/frontend";
    npmDepsHash = "sha256-lFuANabOi3pb1mxUg4B/K6d6B+wxfRTLOe40WlQwoMU=";
    installPhase = ''
      runHook preInstall
      cp -r dist $out
      runHook postInstall
    '';
  };
in
buildGoModule (finalAttrs: {
  pname = "garage-ui";
  inherit version src;
  sourceRoot = "${finalAttrs.src.name}/backend";

  vendorHash = "sha256-HSDpfmNbV0a2hNC0TytrzcDjJZpnUFbSZ1mtnt60JRw=";

  nativeBuildInputs = [
    go-swag
    makeWrapper
  ];

  # routes.go imports the swag-generated `docs` package; generate it before build.
  preBuild = ''
    swag init
  '';

  ldflags = [
    "-s"
    "-w"
    "-X main.version=${version}"
  ];

  doCheck = false;

  # routes.go hardcodes FrontendPath=./frontend/dist (cwd-relative); ship dist
  # alongside and pin cwd with --chdir.
  postInstall = ''
    mkdir -p $out/share/garage-ui/frontend
    cp -r ${frontend} $out/share/garage-ui/frontend/dist
    wrapProgram $out/bin/garage-ui --chdir $out/share/garage-ui
  '';

  passthru = {
    inherit frontend;
    # --subpackage updates the frontend npmDepsHash, which nix-update
    # otherwise never touches (nested buildNpmPackage in a let binding).
    updateScript = nix-update-script {
      extraArgs = [
        "--subpackage"
        "frontend"
      ];
    };
  };

  meta = {
    description = "Garage admin UI with OIDC and team access control";
    homepage = "https://github.com/Noooste/garage-ui";
    license = lib.licenses.mit;
    mainProgram = "garage-ui";
  };
})
