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
        vm-base = inputs.nixos-generators.nixosGenerate {
          inherit system;
          modules = [ ./vm-base.nix ];
          specialArgs = { inherit inputs mylib; };
          format = "iso";
        };
        lxc-base = inputs.nixos-generators.nixosGenerate {
          inherit system;
          modules = [ ./lxc-base.nix ];
          specialArgs = { inherit inputs mylib; };
          format = "proxmox-lxc";
        };
      };
    };
}
