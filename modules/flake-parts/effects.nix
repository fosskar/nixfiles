{ inputs, withSystem, ... }:
{
  flake.herculesCI =
    _args:
    withSystem "x86_64-linux" (
      { pkgs, config, ... }:
      let
        inherit (inputs.nixbot.lib.effects { inherit pkgs; }) mkEffect;

        repo = "fosskar/nixfiles";

        gitName = "fosskar[bot]";
        gitEmail = "300917551+fosskar[bot]@users.noreply.github.com";

        # Shared plumbing for every repo-mutating scheduled effect: nixbot mounts a
        # pushable clone of the effect's commit at $NIXBOT_EFFECT_CHECKOUT (also the
        # working directory) with an authenticated `origin`, so only the API/nix side
        # of the forge token has to be requested here (GitToken). It is a github app
        # installation token, so it serves nix-update and changelog enrichment too.
        mkRepoEffect =
          name: command:
          mkEffect {
            name = "effect-${name}";
            checkout = true;
            inputs = [
              pkgs.git
              pkgs.nix
              config.packages.updater
            ];
            secretsMap.git.type = "GitToken";
            effectScript = ''
              set -euo pipefail
              token=$(jq -re '.git.data.token' "$HERCULES_CI_SECRETS_JSON")
              export FORGE_TOKEN="$token"
              export GITHUB_TOKEN="$token"
              export NIX_CONFIG="experimental-features = nix-command flakes
              access-tokens = github.com=$token"

              git config --global user.name '${gitName}'
              git config --global user.email '${gitEmail}'

              git config remote.origin.promisor true
              git config remote.origin.partialclonefilter blob:none

              # nixbot's mkEffect setup hook writes the state API auth header
              # into $PWD, the checkout; unused here and it dirties the tree
              rm hercules-ci.headers

              ${command}
            '';
          };

        # Renovate clones the repo itself, so this skips mkRepoEffect's checkout.
        # Tools are pinned on PATH via `inputs` (binarySource=global) instead of a
        # runtime `nix shell`: go for gomodTidy, nix for update-vendor-hash.sh.
        renovate = mkEffect {
          name = "effect-renovate";
          inputs = [
            pkgs.renovate
            pkgs.go
            pkgs.nix
            pkgs.git
          ];
          secretsMap.git.type = "GitToken";
          effectScript = ''
            set -euo pipefail
            export NIX_CONFIG="experimental-features = nix-command flakes"

            token=$(jq -re '.git.data.token' "$HERCULES_CI_SECRETS_JSON")
            export RENOVATE_TOKEN="$token"
            export RENOVATE_GITHUB_COM_TOKEN="$token"

            export RENOVATE_PLATFORM=github
            export RENOVATE_REPOSITORIES=${repo}
            export RENOVATE_GIT_AUTHOR='${gitName} <${gitEmail}>'
            export RENOVATE_ALLOWED_COMMANDS='["^bash packages/update-vendor-hash\\.sh (live-ocr|opencloud-ocr)$"]'
            export RENOVATE_BINARY_SOURCE=global
            export LOG_LEVEL=info

            renovate
          '';
        };
      in
      {
        onSchedule.renovate = {
          when = {
            hour = 20;
            minute = 0;
          };
          outputs.effects.renovate = renovate;
        };

        onSchedule.update-pkgs = {
          when = {
            hour = 2;
            minute = 0;
          };
          outputs.effects.update-pkgs = mkRepoEffect "update-pkgs" ''
            updater-packages
          '';
        };

        onSchedule.update-flake-inputs = {
          when = {
            hour = 22;
            minute = 0;
          };
          outputs.effects.update-flake-inputs = mkRepoEffect "update-flake-inputs" ''
            updater-flake-inputs
          '';
        };
      }
    );
}
