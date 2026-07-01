{ inputs, self, ... }:
let
  pkgs = inputs.nixpkgs.legacyPackages.x86_64-linux;
  updater = self.packages.x86_64-linux.update-pkgs;

  # Shared plumbing for every repo-mutating scheduled effect: request
  # nixbot's forge token (GitToken), authenticate git via ~/.netrc so the
  # token stays out of the URL and logs, clone, then run command.
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
        export FORGE_TOKEN="$token" GIT_TERMINAL_PROMPT=0
        umask 077
        printf 'machine codeberg.org login oauth2 password %s\n' "$token" >"$HOME/.netrc"

        git config --global user.name nixbot
        git config --global user.email nixbot@nx3.eu
        git config --global safe.directory '*'

        git clone --depth 1 https://codeberg.org/fosskar/nixfiles.git repo
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
