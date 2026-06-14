{ lib, self, ... }:
{
  # nflib helper set (defined in lib/), exposed as a flake output + propagated
  # into modules via clan specialArgs (nflib = config.flake.lib).
  flake.lib = import ../../lib { inherit lib self; };
}
