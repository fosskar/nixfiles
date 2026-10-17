# pinned release asset; the device checks its sha256 before apk installs it.
# both devices are filogic boards (DISTRIB_ARCH aarch64_cortex-a53, apk)
let
  tag = "v0.21.0";
  version = "0.21.0-r1";
  arch = "aarch64_cortex-a53";
  sha256 = "d6b51583360bc19a62d66132fb510c73be237746bc742cdb479adb3c42d15f29";
  url = "https://github.com/vernette/beszel-agent-openwrt/releases/download/${tag}/beszel-agent-${version}_${arch}.apk";
in
{
  name = "beszel-agent";
  checkCommand = ''apk list -I beszel-agent | grep -q "^beszel-agent-${version} "'';
  installCommand = ''
    (
      set -e
      . /etc/openwrt_release
      [ "$DISTRIB_ARCH" = ${arch} ] || { echo "beszel-agent: unexpected arch $DISTRIB_ARCH" >&2; exit 1; }
      rm -f /tmp/beszel-agent.apk
      wget -qO /tmp/beszel-agent.apk ${url}
      [ "$(sha256sum /tmp/beszel-agent.apk | cut -d ' ' -f 1)" = ${sha256} ] || { echo "beszel-agent: sha256 mismatch" >&2; rm -f /tmp/beszel-agent.apk; exit 1; }
      apk add --allow-untrusted /tmp/beszel-agent.apk
      rm -f /tmp/beszel-agent.apk
      /etc/init.d/beszel-agent restart
    )
  '';
}
