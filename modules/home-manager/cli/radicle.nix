_: {
  flake.modules.homeManager.radicle =
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
            "z6Mkfs9BG9u9P6mzwH1ioSQiS6TbpXGUHiAWrmVjYtLnzP9G@seed.fosskar.eu:8776"
          ];
          web.pinned.repositories = [
            "rad:z4X1gDvBMpZLyzkQEj7dCMpurwqkV" # nixfiles
          ];
        };
      };

      services.radicle.node.enable = true;

      home.packages = [
        (pkgs.writeShellScriptBin "rad-delegate" ''
          set -euo pipefail
          dids=(
            did:key:z6MkuikgFx2EtrJufK4vYELecHj7Qg5cTpBRZHhsb8t9M8Qq # desktop
            did:key:z6Mkqumzp6etEF91c57YnvHkrwq4DkUqVusTSTdychiEDLLJ # lpt-titan
            did:key:z6MkjNSSqPTQm5AnKdmgVom22nr4ZK57bj7dSm1gZeFX4MxN # nixworker
          )

          for rid in $(rad node inventory); do
            delegates=$(rad inspect "$rid" --delegates)
            missing=()
            for did in "''${dids[@]}"; do
              if ! printf '%s\n' "$delegates" | grep -Fqx "$did"; then
                missing+=(--delegate "$did")
              fi
            done

            if (( ''${#missing[@]} == 0 )); then
              echo "✓ $rid already has all device delegates"
              continue
            fi

            rad id update --repo "$rid" --title "add device" "''${missing[@]}"
            rad sync --announce "$rid"
          done
        '')
      ];
    };
}
