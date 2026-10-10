{
  lib,
  stdenvNoCC,
  fetchzip,
  nix-update-script,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "jellyfin-plugin-tvdb";
  version = "24";

  src = fetchzip {
    url = "https://github.com/jellyfin/jellyfin-plugin-tvdb/releases/download/v${finalAttrs.version}/thetvdb_${finalAttrs.version}.0.0.0.zip";
    hash = "sha256-nSidMGw+gkILzPVBvgiIYraC+9QuRj70epr5jKstybY=";
    stripRoot = false;
  };

  dontConfigure = true;
  dontBuild = true;
  dontFixup = true;

  installPhase = ''
    runHook preInstall
    cp -r . $out
    runHook postInstall
  '';

  passthru.updateScript = nix-update-script {
    extraArgs = [
      "--version-regex"
      "^v(\\d+)$"
    ];
  };

  meta = {
    description = "Jellyfin plugin to fetch TV metadata from TheTVDB";
    homepage = "https://github.com/jellyfin/jellyfin-plugin-tvdb";
    license = lib.licenses.gpl3Only;
  };
})
