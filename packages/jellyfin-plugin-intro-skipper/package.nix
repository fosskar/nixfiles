{
  lib,
  stdenvNoCC,
  fetchzip,
  nix-update-script,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "jellyfin-plugin-intro-skipper";
  version = "12.0.6.0";

  src = fetchzip {
    url = "https://github.com/intro-skipper/intro-skipper/releases/download/12.0/v${finalAttrs.version}/intro-skipper-v${finalAttrs.version}.zip";
    hash = "sha256-g8Oiyt4NK8pyCXt2M1B7EpEL71kUGGkxtXSzKndUuOQ=";
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
          guid = "c83d86bb-a1e0-4c35-a113-e2101cf4ee6b";
          name = "Intro Skipper";
          overview = "Automatically detect and skip intros in television episodes";
          description = "Analyzes the audio of television episodes and detects introduction sequences.";
          owner = "AbandonedCart, rlauuzo, jumoog (forked from ConfusedPolarBear)";
          category = "MoviesAndShows";
          inherit (finalAttrs) version;
          targetAbi = "12.0.0.0";
        }
      )
    } > $out/meta.json
    runHook postInstall
  '';

  # releases are tagged per jellyfin abi as <abi>/v<version>
  passthru.updateScript = nix-update-script {
    extraArgs = [
      "--version-regex"
      "^12\\.0/v(12\\.\\d+\\.\\d+\\.\\d+)$"
    ];
  };

  meta = {
    description = "Jellyfin plugin to detect and skip intros in television episodes";
    homepage = "https://github.com/intro-skipper/intro-skipper";
    license = lib.licenses.gpl3Only;
  };
})
