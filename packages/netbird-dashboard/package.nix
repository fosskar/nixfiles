{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
  nix-update-script,
}:
buildNpmPackage rec {
  pname = "netbird-dashboard";
  version = "2.39.0";

  src = fetchFromGitHub {
    owner = "netbirdio";
    repo = "dashboard";
    rev = "v${version}";
    hash = "sha256-9sSK9RBbe+u/sNt/5nsYJgS8QdBNdHMFUTrSggZiLos=";
  };

  npmDepsHash = "sha256-Ze+1r5Uh+wdm3MuVr93oS2itodx9Zdv+JYO6Uji1saw=";
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
