{
  lib,
  stdenvNoCC,
  fetchurl,
  nix-update-script,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "talos-metal-iso";
  version = "1.14.4";

  src = fetchurl {
    url = "https://github.com/siderolabs/talos/releases/download/v${finalAttrs.version}/metal-amd64.iso";
    hash = "sha256-BrONxG8oDTYJf5P/+ZLUzvHZaZUcGKniZ7OS2Ra8MjA=";
  };

  dontUnpack = true;
  dontConfigure = true;
  dontBuild = true;
  dontFixup = true;

  installPhase = ''
    runHook preInstall
    cp $src $out
    runHook postInstall
  '';

  # stable releases only; upstream also tags alphas and betas
  passthru.updateScript = nix-update-script {
    extraArgs = [
      "--version-regex"
      "^v(\\d+\\.\\d+\\.\\d+)$"
    ];
  };

  meta = {
    description = "Talos Linux metal installer ISO for amd64";
    homepage = "https://github.com/siderolabs/talos";
    license = lib.licenses.mpl20;
    platforms = [ "x86_64-linux" ];
  };
})
