{ inputs, self, ... }:
let
  inherit (inputs.nixpkgs) lib;
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
            specialArgs = { inherit inputs; };
          }).config.system.build.isoImage;
      };
    };
}
