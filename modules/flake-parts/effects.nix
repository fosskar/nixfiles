{ inputs, ... }:
let
  pkgs = inputs.nixpkgs.legacyPackages.x86_64-linux;

  forgeHost = "github.com";
  repo = "fosskar/nixfiles";

  # Shared plumbing for every repo-mutating scheduled effect: request
  # nixbot's forge token (GitToken), clone with it, then run command. git
  # redacts credentials from URLs in its output, so the token stays out of
  # the public effect log.
  mkRepoEffect =
    name: command:
    pkgs.runCommand "effect-${name}"
      {
        nativeBuildInputs = [
          pkgs.cacert
          pkgs.git
          pkgs.jq
          pkgs.nix
        ];
        # The GitToken is a github app installation token, so it serves the
        # direct github API calls (nix-update, changelog enrichment) too.
        secretsMap = builtins.toJSON { git.type = "GitToken"; };
        HOME = "/build";
      }
      ''
        set -euo pipefail
        token=$(jq -re '.git.data.token' "$HERCULES_CI_SECRETS_JSON")
        export FORGE_TOKEN="$token"
        export GITHUB_TOKEN="$token"
        export NIX_CONFIG="experimental-features = nix-command flakes
        access-tokens = github.com=$token"

        git config --global user.name 'fosskar[bot]'
        git config --global user.email '300917551+fosskar[bot]@users.noreply.github.com'
        git config --global safe.directory '*'

        git clone --depth 1 --progress "https://oauth2:$token@${forgeHost}/${repo}.git" repo
        cd repo

        ${command}
      '';

  # Renovate clones the repo itself, so this skips mkRepoEffect's clone. Tools
  # are pinned on PATH via nativeBuildInputs (binarySource=global) instead of a
  # runtime `nix shell`: go for gomodTidy, nix for update-vendor-hash.sh.
  renovate =
    pkgs.runCommand "effect-renovate"
      {
        nativeBuildInputs = [
          pkgs.renovate
          pkgs.go
          pkgs.nix
          pkgs.git
          pkgs.cacert
          pkgs.jq
        ];
        secretsMap = builtins.toJSON { git.type = "GitToken"; };
        HOME = "/build";
      }
      ''
        set -euo pipefail
        export NIX_CONFIG="experimental-features = nix-command flakes"

        token=$(jq -re '.git.data.token' "$HERCULES_CI_SECRETS_JSON")
        export RENOVATE_TOKEN="$token"
        export RENOVATE_GITHUB_COM_TOKEN="$token"

        export RENOVATE_PLATFORM=github
        export RENOVATE_REPOSITORIES=${repo}
        export RENOVATE_GIT_AUTHOR='fosskar[bot] <300917551+fosskar[bot]@users.noreply.github.com>'
        export RENOVATE_ALLOWED_COMMANDS='["^bash packages/live-ocr/update-vendor-hash\\.sh$"]'
        export RENOVATE_BINARY_SOURCE=global
        export LOG_LEVEL=info

        renovate
      '';
in
{
  flake.effects = _args: {
    onSchedule.renovate = {
      when = {
        hour = 1;
        minute = 0;
      };
      outputs.effects.renovate = renovate;
    };

    onSchedule.update-pkgs = {
      when = {
        hour = 2;
        minute = 0;
      };
      # apps on the cloned repo's own flake keep the effect body generic;
      # other repos use nix run "github:fosskar/nixfiles#updater-packages"
      # instead - no flake input required.
      outputs.effects.update-pkgs = mkRepoEffect "update-pkgs" ''
        nix run .#updater-packages
      '';
    };

    onSchedule.update-flake-inputs = {
      when = {
        hour = 4;
        minute = 0;
      };
      outputs.effects.update-flake-inputs = mkRepoEffect "update-flake-inputs" ''
        nix run .#updater-flake-inputs
      '';
    };
  };
}
