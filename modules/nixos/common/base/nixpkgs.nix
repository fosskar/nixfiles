{
  flake.modules.nixos.base =
    { self, inputs, ... }:
    {
      nixpkgs = {
        overlays = [ self.overlays.default ] ++ import (self + "/overlays") { inherit inputs; };

        config.allowUnfree = true;
      };
    };
}
