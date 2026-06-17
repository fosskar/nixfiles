{ inputs, self, ... }:
let
  inherit (inputs.nixpkgs) lib;
  nflib = import (self.outPath + "/lib") { inherit lib; };
in
{
  perSystem =
    { system, ... }:
    {
      packages = {
        # build iso using upstream nixpkgs (no nixos-generators needed)
        # usage: nix build .#vm-base
        vm-base =
          (lib.nixosSystem {
            inherit system;
            modules = [ (self.outPath + "/images/vm-base.nix") ];
            specialArgs = { inherit inputs nflib; };
          }).config.system.build.isoImage;
      };
    };
}
