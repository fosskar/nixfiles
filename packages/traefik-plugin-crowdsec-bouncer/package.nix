{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
  nix-update-script,
}:
# plugin source for traefik's experimental.localPlugins; traefik interprets it
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "traefik-plugin-crowdsec-bouncer";
  version = "1.7.1";

  src = fetchFromGitHub {
    owner = "maxlerebourg";
    repo = "crowdsec-bouncer-traefik-plugin";
    tag = "v${finalAttrs.version}";
    hash = "sha256-hefOKDVsBxn+rCAylPHqbCNfPMbU/vtO4QpiftIPcUU=";
  };

  dontConfigure = true;
  dontBuild = true;
  dontFixup = true;

  installPhase = ''
    runHook preInstall
    cp -r . $out
    runHook postInstall
  '';

  # stable releases only; upstream also tags alphas
  passthru.updateScript = nix-update-script {
    extraArgs = [
      "--version-regex"
      "^v(\\d+\\.\\d+\\.\\d+)$"
    ];
  };

  meta = {
    description = "CrowdSec bouncer middleware plugin for traefik";
    homepage = "https://github.com/maxlerebourg/crowdsec-bouncer-traefik-plugin";
    license = lib.licenses.asl20;
  };
})
