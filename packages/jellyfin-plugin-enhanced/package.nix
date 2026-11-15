{
  lib,
  stdenvNoCC,
  fetchzip,
  nix-update-script,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "jellyfin-plugin-enhanced";
  version = "12.16.0.0";

  src = fetchzip {
    url = "https://github.com/n00bcodr/Jellyfin-Enhanced/releases/download/${finalAttrs.version}/Jellyfin.Plugin.JellyfinEnhanced_12.0.0.zip";
    hash = "sha256-2shYCzD3JZ5/iXf6nkup5Q2y1QAWt3hwlnNA0drrfZk=";
    stripRoot = false;
  };

  dontConfigure = true;
  dontBuild = true;
  dontFixup = true;

  # the release zip lacks the meta.json the jellyfin repository install writes
  installPhase = ''
    runHook preInstall
    cp -r . $out
    echo ${
      lib.escapeShellArg (
        builtins.toJSON {
          guid = "f69e946a-4b3c-4e9a-8f0a-8d7c1b2c4d9b";
          name = "Jellyfin Enhanced";
          overview = "Jellyfin Enhanced and Jellyfin Elsewhere for a better Jellyfin experience.";
          description = "A combination of the Jellyfin Enhanced and Jellyfin Elsewhere userscripts, providing a comprehensive set of tweaks and features for Jellyfin.";
          owner = "n00bcodr";
          category = "General";
          inherit (finalAttrs) version;
          targetAbi = "12.0.0.0";
        }
      )
    } > $out/meta.json
    runHook postInstall
  '';

  passthru.updateScript = nix-update-script {
    extraArgs = [
      "--version-regex"
      "^(\\d+\\.\\d+\\.\\d+\\.\\d+)$"
    ];
  };

  meta = {
    description = "Jellyfin plugin adding Seerr requests and web interface tools";
    homepage = "https://github.com/n00bcodr/Jellyfin-Enhanced";
    license = lib.licenses.gpl3Only;
  };
})
