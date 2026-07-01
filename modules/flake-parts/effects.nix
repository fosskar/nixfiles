{ inputs, self, ... }:
let
  # Effects build/run on the nixbot host (nixworker, x86_64-linux).
  pkgs = inputs.nixpkgs.legacyPackages.x86_64-linux;

  # Packaged updater (nix-update/git/nix wired on its PATH); runs against
  # a fresh clone it makes itself.
  updater = self.packages.x86_64-linux.update-packages;

  # Raw effect derivation: nixbot runs its builder inside the effects
  # bwrap sandbox. secretsMap requests nixbot's forge token as a hercules
  # GitToken, exposed at $HERCULES_CI_SECRETS_JSON (.git.data.token).
  mkEffect =
    name: script:
    pkgs.runCommand "effect-${name}" {
      nativeBuildInputs = [ pkgs.cacert ];
      secretsMap = builtins.toJSON { git.type = "GitToken"; };
      HOME = "/build";
    } script;
in
{
  flake.herculesCI = _args: {
    # Daily package updates; one PR per changed package group. Replaces
    # .forgejo/workflows/update-packages.yml.
    onSchedule.update-packages = {
      when = {
        hour = 2;
        minute = 0;
      };
      outputs.effects.update-packages = mkEffect "update-packages" ''
        export NIX_CONFIG="experimental-features = nix-command flakes"
        exec ${updater}/bin/update-packages
      '';
    };
  };
}
