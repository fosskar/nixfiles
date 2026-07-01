{ inputs, self, ... }:
let
  pkgs = inputs.nixpkgs.legacyPackages.x86_64-linux;
  updater = self.packages.x86_64-linux.update-pkgs;

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
        ];
        secretsMap = builtins.toJSON {
          git.type = "GitToken";
          github = "github-api";
        };
        HOME = "/build";
      }
      ''
        set -euo pipefail
        export NIX_CONFIG="experimental-features = nix-command flakes"
        # Stream output to the live effect log instead of buffering it.
        export PYTHONUNBUFFERED=1

        token=$(jq -r '.git.data.token' "$HERCULES_CI_SECRETS_JSON")
        export FORGE_TOKEN="$token"
        # authenticates github API calls (nix-update reads GITHUB_TOKEN).
        export GITHUB_TOKEN=$(jq -r '.github.data.token' "$HERCULES_CI_SECRETS_JSON")

        git config --global user.name nixbot
        git config --global user.email nixbot@nx3.eu
        git config --global safe.directory '*'

        git clone --depth 1 --progress "https://oauth2:$token@codeberg.org/fosskar/nixfiles.git" repo
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
        secretsMap = builtins.toJSON {
          git.type = "GitToken";
          github = "github-api";
        };
        HOME = "/build";
      }
      ''
        set -euo pipefail
        export NIX_CONFIG="experimental-features = nix-command flakes"

        export RENOVATE_TOKEN=$(jq -r '.git.data.token' "$HERCULES_CI_SECRETS_JSON")
        export RENOVATE_GITHUB_COM_TOKEN=$(jq -r '.github.data.token' "$HERCULES_CI_SECRETS_JSON")

        export RENOVATE_PLATFORM=forgejo
        export RENOVATE_ENDPOINT=https://codeberg.org
        export RENOVATE_REPOSITORIES=fosskar/nixfiles
        export RENOVATE_ALLOWED_COMMANDS='["^bash packages/live-ocr/update-vendor-hash\\.sh$"]'
        export RENOVATE_BINARY_SOURCE=global
        export LOG_LEVEL=info

        renovate
      '';
in
{
  flake.effects = _args: {
    onSchedule.update-pkgs = {
      when = {
        hour = 2;
        minute = 0;
      };
      outputs.effects.update-pkgs = mkRepoEffect "update-pkgs" ''
        ${updater}/bin/update-pkgs
      '';
    };
    onSchedule.renovate = {
      when = {
        hour = 1;
        minute = 0;
      };
      outputs.effects.renovate = renovate;
    };
  };
}
