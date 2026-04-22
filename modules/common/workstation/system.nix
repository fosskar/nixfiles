{
  flake.modules.nixos.workstation =
    { lib, ... }:
    {
      environment.stub-ld.enable = lib.mkDefault true;
    };
}
