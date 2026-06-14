{
  inputs,
  self,
  withSystem,
  ...
}:
let
  inherit (inputs.nixpkgs) lib;
in
{
  flake.overlays = {
    # local packages, exposed as pkgs.custom.*. derived from the single package
    # discovery in packages/flake-module.nix (no second scan).
    custom =
      _final: prev:
      withSystem prev.stdenv.hostPlatform.system (
        { config, ... }:
        {
          custom = config.packages;
        }
      );
    stable = import ../../overlays/stable-pkgs { inherit inputs; };
    tuned-minimal = import ../../overlays/tuned-minimal;
    llm-agents = inputs.llm-agents.overlays.default;

    # default = all overlays combined
    default = lib.composeManyExtensions [
      self.overlays.custom
      self.overlays.stable
      self.overlays.tuned-minimal
      self.overlays.llm-agents
    ];
  };
}
