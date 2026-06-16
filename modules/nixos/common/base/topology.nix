{ inputs, ... }:
{
  # nixos aspect: every host that imports base participates in the topology,
  # contributing its interfaces/services and its `topology.self` declarations.
  # the flake-level wiring + global graph live in modules/flake-parts/topology.nix.
  flake.modules.nixos.base.imports = [ inputs.nix-topology.nixosModules.default ];
}
