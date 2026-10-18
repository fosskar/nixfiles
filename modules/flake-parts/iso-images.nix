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

  # outside perSystem: x86_64 checks would build every package, this one too
  # usage: nix build .#packages.aarch64-linux.ha-green-installer
  flake.packages.aarch64-linux.ha-green-installer =
    (lib.nixosSystem {
      modules = [
        self.modules.nixos.haGreen
        (self.outPath + "/images/ha-green-installer.nix")
      ];
      specialArgs = { inherit inputs; };
    }).config.system.build.sdImage;
}
