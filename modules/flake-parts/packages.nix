{
  inputs,
  self,
  withSystem,
  ...
}:
{
  imports = [ inputs.pkgs-by-name-for-flake-parts.flakeModule ];

  # local packages (config.packages) -> pkgs.local.*
  flake.overlays.default =
    _final: prev:
    withSystem prev.stdenv.hostPlatform.system (
      { config, ... }:
      {
        local = config.packages;
      }
    );

  perSystem =
    { system, ... }:
    {
      # no local-packages bridge here: it is config.packages, would recurse
      _module.args.pkgs = import inputs.nixpkgs {
        inherit system;
        config = {
          allowUnfree = true;
          allowDeprecatedx86_64Darwin = true;
        };
        overlays = import (self.outPath + "/overlays") { inherit inputs; };
      };

      pkgsDirectory = self.outPath + "/packages";
    };
}
