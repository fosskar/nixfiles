{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
  nix-update-script,
}:
# plugin source for traefik's experimental.localPlugins; traefik interprets it
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "traefik-plugin-geoblock";
  version = "0.3.8";

  src = fetchFromGitHub {
    owner = "PascalMinder";
    repo = "geoblock";
    tag = "v${finalAttrs.version}";
    hash = "sha256-afooxatN7TomMg0TF7PISHK1VwiZxj1Et825rXprBqU=";
  };

  dontConfigure = true;
  dontBuild = true;
  dontFixup = true;

  installPhase = ''
    runHook preInstall
    cp -r . $out
    runHook postInstall
  '';

  # stable releases only
  passthru.updateScript = nix-update-script {
    extraArgs = [
      "--version-regex"
      "^v(\\d+\\.\\d+\\.\\d+)$"
    ];
  };

  meta = {
    description = "Country-based geoblocking middleware plugin for traefik";
    homepage = "https://github.com/PascalMinder/geoblock";
    license = lib.licenses.asl20;
  };
})
