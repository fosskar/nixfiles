{ inputs, self, ... }:
let
  inherit (inputs.nixpkgs) lib;
in
{
  flake.overlays = {
    custom = import ./custom-pkgs;
    stable = import ./stable-pkgs { inherit inputs; };
    master = import ./master-pkgs { inherit inputs; };
    tuned-minimal = import ./tuned-minimal;

    # default = all overlays combined
    default = lib.composeManyExtensions [
      self.overlays.custom
      self.overlays.stable
      self.overlays.master
      self.overlays.tuned-minimal
    ];
  };
}
