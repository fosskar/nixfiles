{ pkgs, ... }:
{
  programs.radicle = {
    enable = true;
    settings = {
      node = {
        alias = "fosskar";
      };
      preferredSeeds = [
        "z6Mkuo44bkXzzYZsiR8x5PftuNaybCCxL7magvUTh76VBCLa@seed.fosskar.eu:8776"
      ];
      web.pinned.repositories = [
        "rad:z4X1gDvBMpZLyzkQEj7dCMpurwqkV" # nixfiles
      ];
    };
  };

  services.radicle.node = {
    enable = true;
    lazy.enable = true;
  };

  home.packages = [
    pkgs.radicle-desktop
    # one-shot key fetch from proton-pass on a new machine. requires prior
    # `pass-cli login`. drops the keys at ~/.radicle/keys/{radicle,radicle.pub};
    # radicle reads them like any other identity from then on.
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
