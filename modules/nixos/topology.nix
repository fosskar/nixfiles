{ inputs, ... }:
{
  imports = [ inputs.nix-topology.flakeModule ];

  # nix-topology collects interfaces/services from every host that imports its
  # nixos module. wire it into base so all machines participate.
  # build per-system diagrams: `nix build .#topology.x86_64-linux.config.output`
  flake.modules.nixos.base.imports = [ inputs.nix-topology.nixosModules.default ];
}
