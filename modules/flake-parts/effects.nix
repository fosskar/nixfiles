{ inputs, self, ... }:
let
  pkgs = inputs.nixpkgs.legacyPackages.x86_64-linux;
  updater = self.packages.x86_64-linux.update-pkgs;

  # Shared plumbing for every repo-mutating scheduled effect: request
  # nixbot's forge token (GitToken), authenticate git via GIT_ASKPASS so
  # the token never lands in a remote URL, clone, then run command.
  mkRepoEffect =
    name: command:
    pkgs.runCommand "effect-${name}"
      {
        nativeBuildInputs = [
          pkgs.cacert
          pkgs.git
          pkgs.jq
        ];
        secretsMap = builtins.toJSON { git.type = "GitToken"; };
        HOME = "/build";
      }
      ''
        set -euo pipefail
        export NIX_CONFIG="experimental-features = nix-command flakes"

        token=$(jq -r '.git.data.token' "$HERCULES_CI_SECRETS_JSON")
        export FORGE_TOKEN="$token" GIT_TOKEN="$token"
        export GIT_ASKPASS="$HOME/.git-askpass" GIT_TERMINAL_PROMPT=0
        printf '#!/usr/bin/env bash\nprintf "%s\n" "$GIT_TOKEN"\n' >"$GIT_ASKPASS"
        chmod +x "$GIT_ASKPASS"

        git config --global user.name nixbot
        git config --global user.email nixbot@nx3.eu
        git config --global safe.directory '*'

        git clone https://oauth2@codeberg.org/fosskar/nixfiles.git repo
        cd repo

        ${command}
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
  };
}
