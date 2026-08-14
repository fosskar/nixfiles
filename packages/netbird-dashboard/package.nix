{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
  nix-update-script,
}:
buildNpmPackage rec {
  pname = "netbird-dashboard";
  version = "2.91.0";

  src = fetchFromGitHub {
    owner = "netbirdio";
    repo = "dashboard";
    rev = "v${version}";
    hash = "sha256-IqqFd4xlcSlWG/N/0aS1SKMizGU6ymEF8V1yteRl9Wg=";
  };

  npmDepsHash = "sha256-KWEVpESs71ng9uGbgP1xHihFhRONDE81wx6y3O4BoAY=";
  npmFlags = [ "--legacy-peer-deps" ];

  # auth config string-replaced post-build in JS bundle so it works for any domain
  installPhase = ''
    cp -R out $out
  '';

  env = {
    CYPRESS_INSTALL_BINARY = 0;
  };

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "netbird management dashboard (static web UI)";
    homepage = "https://github.com/netbirdio/dashboard";
    license = lib.licenses.bsd3;
    mainProgram = "netbird-dashboard";
  };
}
