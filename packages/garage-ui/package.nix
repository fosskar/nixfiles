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
  version = "0.8.4";

  src = fetchFromGitHub {
    owner = "Noooste";
    repo = "garage-ui";
    tag = "v${version}";
    hash = "sha256-pRD/uFoKGfKJOxkmx+DXGb+p0+z6oXZVCzpejzlJpxA=";
  };

  frontend = buildNpmPackage {
    pname = "garage-ui-frontend";
    inherit version src;
    sourceRoot = "${src.name}/frontend";
    npmDepsHash = "sha256-ywrT4d8fvSeHTsggTa9599Mg8zshnLv+NDXZ6mRIGRk=";
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

  vendorHash = "sha256-w1ESuQkFw10X3v/L4iHq6DwxCc9Wbu6h/ujzJqHOipM=";

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

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "Garage admin UI with OIDC and team access control";
    homepage = "https://github.com/Noooste/garage-ui";
    license = lib.licenses.mit;
    mainProgram = "garage-ui";
  };
})
