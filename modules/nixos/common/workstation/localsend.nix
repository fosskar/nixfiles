{
  flake.modules.nixos.workstation =
    { lib, ... }:
    {
      programs.localsend.enable = lib.mkDefault true;
    };
}
