{
  inputs,
  self,
  rootPath,
  ...
}:
{
  # local packages: auto-discovered from packages/ (RFC-140 by-name layout,
  # <name>/package.nix) by pkgs-by-name-for-flake-parts. exposed as flake
  # packages and, via overlays/flake-module.nix, as pkgs.custom.*.
  imports = [ inputs.pkgs-by-name-for-flake-parts.flakeModule ];

  perSystem =
    { system, ... }:
    {
      # perSystem pkgs used to callPackage the local packages (and by other
      # perSystem modules: treefmt, shells).
      _module.args.pkgs = import inputs.nixpkgs {
        inherit system;
        config = {
          allowUnfree = true;
          allowDeprecatedx86_64Darwin = true;
        };
        # same overlays as the machines (self.overlays.default), minus custom/
        # default — those contain config.packages and would recurse.
        overlays = [
          self.overlays.stable
          self.overlays.tuned-minimal
          self.overlays.llm-agents
        ];
      };

      pkgsDirectory = rootPath + "/packages";
    };
}
