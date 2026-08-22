{ pkgs, ... }:
{
  services.radicle.node.lazy.enable = true;

  home.packages = [
    pkgs.radicle-desktop
    # one-shot identity fetch from proton-pass on new machine; needs prior `pass-cli login`
    (pkgs.writeShellScriptBin "radicle-fetch-key" ''
      set -euo pipefail
      mkdir -p "$HOME/.radicle/keys"
      chmod 700 "$HOME/.radicle/keys"

      ${pkgs.proton-pass-cli}/bin/pass-cli item view \
        --vault-name Personal \
        --item-title "Radicle fosskar" \
        --field "Private Key" \
        --output human \
        > "$HOME/.radicle/keys/radicle"
      chmod 600 "$HOME/.radicle/keys/radicle"

      ${pkgs.proton-pass-cli}/bin/pass-cli item view \
        --vault-name Personal \
        --item-title "Radicle fosskar" \
        --field "Public Key" \
        --output human \
        > "$HOME/.radicle/keys/radicle.pub"

      echo "✓ radicle keys fetched into ~/.radicle/keys"
    '')
  ];
}
