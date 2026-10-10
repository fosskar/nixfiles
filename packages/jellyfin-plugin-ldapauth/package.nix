{
  lib,
  stdenvNoCC,
  fetchzip,
  nix-update-script,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "jellyfin-plugin-ldapauth";
  version = "24";

  src = fetchzip {
    url = "https://github.com/jellyfin/jellyfin-plugin-ldapauth/releases/download/v${finalAttrs.version}/ldap-authentication_${finalAttrs.version}.0.0.0.zip";
    hash = "sha256-yiyoLahv+tzNWB4JVPoC4fxl+gj8IoYVXv0bi2FGlmM=";
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
    description = "Jellyfin plugin to authenticate users against LDAP";
    homepage = "https://github.com/jellyfin/jellyfin-plugin-ldapauth";
    license = lib.licenses.mit;
  };
})
