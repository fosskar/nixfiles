{
  lib,
  stdenvNoCC,
  fetchurl,
  nix-update-script,
}:
# apk for the openwrt router and ap (both filogic, aarch64_cortex-a53);
# the openwrt deploy installs it through passthru.openwrtExternalPackage
let
  arch = "aarch64_cortex-a53";
in
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "beszel-agent-openwrt";
  version = "0.21.0";

  src = fetchurl {
    url = "https://github.com/vernette/beszel-agent-openwrt/releases/download/v${finalAttrs.version}/beszel-agent-${finalAttrs.version}-r1_${arch}.apk";
    hash = "sha256-1rUVgzYLwZpi1mEy+1EMc74jd0a8dCzbR5rbPELRXyk=";
  };

  dontUnpack = true;

  installPhase = ''
    runHook preInstall
    cp $src $out
    runHook postInstall
  '';

  passthru = {
    updateScript = nix-update-script {
      extraArgs = [
        "--version-regex"
        "^v(.*)$"
      ];
    };

    # the device downloads the release asset and checks its sha256 before
    # apk installs it
    openwrtExternalPackage =
      let
        sha256 = builtins.convertHash {
          hash = finalAttrs.src.outputHash;
          toHashFormat = "base16";
        };
      in
      {
        name = "beszel-agent";
        checkCommand = ''apk list -I beszel-agent | grep -q "^beszel-agent-${finalAttrs.version}-r1 "'';
        installCommand = ''
          (
            set -e
            . /etc/openwrt_release
            [ "$DISTRIB_ARCH" = ${arch} ] || { echo "beszel-agent: unexpected arch $DISTRIB_ARCH" >&2; exit 1; }
            rm -f /tmp/beszel-agent.apk
            wget -qO /tmp/beszel-agent.apk ${lib.head finalAttrs.src.urls}
            [ "$(sha256sum /tmp/beszel-agent.apk | cut -d ' ' -f 1)" = ${sha256} ] || { echo "beszel-agent: sha256 mismatch" >&2; rm -f /tmp/beszel-agent.apk; exit 1; }
            apk add --allow-untrusted /tmp/beszel-agent.apk
            rm -f /tmp/beszel-agent.apk
            /etc/init.d/beszel-agent restart
          )
        '';
      };
  };

  meta = {
    description = "Beszel monitoring agent packaged for OpenWrt";
    homepage = "https://github.com/vernette/beszel-agent-openwrt";
    license = lib.licenses.mit;
  };
})
