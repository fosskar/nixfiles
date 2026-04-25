{
  flake.modules.nixos.base =
    { inputs, ... }:
    {
      imports = [ inputs.srvos.nixosModules.mixins-terminfo ];
    };
}
