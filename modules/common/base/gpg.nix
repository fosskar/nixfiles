{
  flake.modules.nixos.base =
    { lib, ... }:
    {
      programs.gnupg.agent.enable = lib.mkDefault true;
    };
}
