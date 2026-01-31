{ inputs, ... }:
let
  inherit (inputs.nixpkgs) lib;
  mylib = import ../lib { inherit lib; };
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
            modules = [ ./vm-base.nix ];
            specialArgs = { inherit inputs mylib; };
          }).config.system.build.isoImage;
      };
    };
}
