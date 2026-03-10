{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
}:

buildNpmPackage rec {
  pname = "netbird-dashboard";
  version = "2.34.0";

  src = fetchFromGitHub {
    owner = "netbirdio";
    repo = "dashboard";
    rev = "v${version}";
    hash = "sha256-zIqC3EvlsikrJzyLMwUVU9pGnBLcR0yNYqpAQg8W7jU=";
  };

  npmDepsHash = "sha256-AYbTtUgo/e9BD5Kg877qUHkj+4l2OJ88rxnquA2789k=";
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
