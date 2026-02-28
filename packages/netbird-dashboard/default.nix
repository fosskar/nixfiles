{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
}:

buildNpmPackage rec {
  pname = "netbird-dashboard";
  version = "2.33.0";

  src = fetchFromGitHub {
    owner = "netbirdio";
    repo = "dashboard";
    rev = "v${version}";
    hash = "sha256-02ivrqgi1TKHvi6unn9MXp3mwI3hbJoNV9pg9QC+z/Q=";
  };

  npmDepsHash = "sha256-shN+XdS5Z2MxEFy453YqqovDUXbde3L9Y7+cPZW53/Y=";
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

  meta = {
    description = "netbird management dashboard (static web UI)";
    homepage = "https://github.com/netbirdio/dashboard";
    license = lib.licenses.bsd3;
    mainProgram = "netbird-dashboard";
  };
}
