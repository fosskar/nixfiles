{
  inputs,
  rootPath,
  ...
}:
{
  imports = [ inputs.pkgs-by-name-for-flake-parts.flakeModule ];

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
        overlays = import (rootPath + "/overlays") { inherit inputs; };
      };

      pkgsDirectory = rootPath + "/packages";
    };
}
