{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
  nix-update-script,
}:
buildNpmPackage rec {
  pname = "netbird-dashboard";
  version = "2.90.5";

  src = fetchFromGitHub {
    owner = "netbirdio";
    repo = "dashboard";
    rev = "v${version}";
    hash = "sha256-dZfjLKWv7Nn0D8YW/8wlmbo+qD6cfu4Z8D/fx5Qrduc=";
  };

  npmDepsHash = "sha256-A6zXrOPdxLepi7XPn67YsY673iFOAgJqCEynn4SYco8=";
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
