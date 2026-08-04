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
  version = "0.11.3";

  src = fetchFromGitHub {
    owner = "Noooste";
    repo = "garage-ui";
    tag = "v${version}";
    hash = "sha256-ABJcdrONwAtBSvSvlL81sZUlZIfJVlleo1OtQojWaI4=";
  };

  frontend = buildNpmPackage {
    pname = "garage-ui-frontend";
    inherit version src;
    sourceRoot = "${src.name}/frontend";
    # upstream v0.11.1 ships a lock where 237 of 437 entries lack
    # resolved/integrity, so fetchNpmDeps never downloads them and npm ci hits
    # the network. this copy adds them back, upstream versions unchanged.
    postPatch = "cp ${./package-lock.json} package-lock.json";
    npmDepsHash = "sha256-mL+6GdZHmsRpXW9GzPgun2sN5JuLTQqA5/2jfTYvvRk=";
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

  passthru = {
    inherit frontend;
    # --subpackage updates the frontend npmDepsHash, which nix-update
    # otherwise never touches (nested buildNpmPackage in a let binding).
    # a version bump also needs ./package-lock.json regenerated from the new
    # upstream lock, else npmConfigHook fails the consistency check.
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
