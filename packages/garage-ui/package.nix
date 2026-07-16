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
  version = "0.10.0";

  src = fetchFromGitHub {
    owner = "Noooste";
    repo = "garage-ui";
    tag = "v${version}";
    hash = "sha256-D+dAHFW9az2E8Bf6aKq5QHc8d9jOYGjSa+5q9PmPuzw=";
  };

  frontend = buildNpmPackage {
    pname = "garage-ui-frontend";
    inherit version src;
    sourceRoot = "${src.name}/frontend";
    npmDepsHash = "sha256-j3h3YmYjmfPv+zKBkgx0n4SdqZT4/KXygREWkqL4G+8=";
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
