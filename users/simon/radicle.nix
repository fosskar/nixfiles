{ pkgs, ... }:
{
  programs.radicle = {
    enable = true;
    settings = {
      node = {
        alias = "fosskar";
        fetch.signedReferences.featureLevel.minimum = "parent";
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
    # add all device identities as delegates to the current radicle repo and
    # announce; safe to re-run (skips identities that are already delegates)
    (pkgs.writeShellScriptBin "rad-delegate" ''
      set -euo pipefail
      # device identity list; extend when adding a machine
      dids=(
        did:key:z6MkuikgFx2EtrJufK4vYELecHj7Qg5cTpBRZHhsb8t9M8Qq # desktop
        did:key:z6Mkqumzp6etEF91c57YnvHkrwq4DkUqVusTSTdychiEDLLJ # lpt-titan
      )
      self=$(rad self --did)
      delegates=$(rad inspect --delegates)
      for did in "''${dids[@]}"; do
        [ "$did" = "$self" ] && continue
        if printf '%s\n' "$delegates" | grep -q "$did"; then
          echo "✓ $did already a delegate"
          continue
        fi
        rad id update --title "add device" --delegate "$did"
      done
      rad sync --announce
    '')
  ];
}
