{ inputs, self, ... }:
let
  inherit (inputs.nixpkgs) lib;
in
{
  flake.overlays = {
    custom = import ./custom-pkgs;
    stable = import ./stable-pkgs { inherit inputs; };
    master = import ./master-pkgs { inherit inputs; };

    # default = all overlays combined
    default = lib.composeManyExtensions [
      self.overlays.custom
      self.overlays.stable
      self.overlays.master
    ];
  };
}
