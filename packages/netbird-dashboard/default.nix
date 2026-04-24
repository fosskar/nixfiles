{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
  nix-update-script,
}:
buildNpmPackage rec {
  pname = "netbird-dashboard";
  version = "2.37.1";

  src = fetchFromGitHub {
    owner = "netbirdio";
    repo = "dashboard";
    rev = "v${version}";
    hash = "sha256-/mrDwRj6A2reMYdbBphgx+cFqjKwefbyWcSiyUOuU00=";
  };

  npmDepsHash = "sha256-Ze+1r5Uh+wdm3MuVr93oS2itodx9Zdv+JYO6Uji1saw=";
  npmFlags = [ "--legacy-peer-deps" ];

  # auth config is baked in at build time via string replacement in the JS bundle.
  # the combined server's embedded IdP serves at /oauth2 on the same domain.
  # these are replaced post-build so they work for any domain.
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
