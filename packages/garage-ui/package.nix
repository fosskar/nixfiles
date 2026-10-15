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
  version = "0.14.0";

  src = fetchFromGitHub {
    owner = "Noooste";
    repo = "garage-ui";
    tag = "v${version}";
    hash = "sha256-XlzNHTSHr8jJUPHmbyxy71hbjHt46fLPk8n8J0oAfLc=";
  };

  frontend = buildNpmPackage {
    pname = "garage-ui-frontend";
    inherit version src;
    sourceRoot = "${src.name}/frontend";
    npmDepsHash = "sha256-5WCijC0b8iXKupE/6n9CqWtD+sfK4pgi4MnOOI1XqJA=";
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

  # behind the smoke build tag, they test a garage started by docker compose
  excludedPackages = [ "tests/smoke" ];

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
