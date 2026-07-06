{ inputs, self, ... }:
let
  pkgs = inputs.nixpkgs.legacyPackages.x86_64-linux;
  updater = self.packages.x86_64-linux.updater;

  forgeHost = "codeberg.org";
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
        secretsMap = builtins.toJSON {
          git.type = "GitToken";
          github = "github-api";
        };
        HOME = "/build";
      }
      ''
        set -euo pipefail
        token=$(jq -re '.git.data.token' "$HERCULES_CI_SECRETS_JSON")
        export FORGE_TOKEN="$token"
        # nix-update and changelog enrichment read GITHUB_TOKEN for their
        # direct github API calls; nix itself only honors access-tokens.
        github_token=$(jq -re '.github.data.token' "$HERCULES_CI_SECRETS_JSON")
        export GITHUB_TOKEN="$github_token"
        export NIX_CONFIG="experimental-features = nix-command flakes
        access-tokens = github.com=$github_token"

        git config --global user.name nixbot
        git config --global user.email nixbot@nx3.eu
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
        secretsMap = builtins.toJSON {
          git.type = "GitToken";
          github = "github-api";
        };
        HOME = "/build";
      }
      ''
        set -euo pipefail
        export NIX_CONFIG="experimental-features = nix-command flakes"

        renovate_token=$(jq -re '.git.data.token' "$HERCULES_CI_SECRETS_JSON")
        export RENOVATE_TOKEN="$renovate_token"
        github_token=$(jq -re '.github.data.token' "$HERCULES_CI_SECRETS_JSON")
        export RENOVATE_GITHUB_COM_TOKEN="$github_token"

        export RENOVATE_PLATFORM=forgejo
        export RENOVATE_ENDPOINT=https://${forgeHost}
        export RENOVATE_REPOSITORIES=${repo}
        export RENOVATE_GIT_AUTHOR='nixbot <nixbot@nx3.eu>'
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
      outputs.effects.update-pkgs = mkRepoEffect "update-pkgs" ''
        ${updater}/bin/updater-packages
      '';
    };

    onSchedule.update-flake-inputs = {
      when = {
        hour = 4;
        minute = 0;
      };
      outputs.effects.update-flake-inputs = mkRepoEffect "update-flake-inputs" ''
        ${updater}/bin/updater-flake-inputs
      '';
    };
  };
}
