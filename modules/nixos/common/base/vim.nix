{
  flake.modules.nixos.base =
    { lib, ... }:
    {
      programs.vim = {
        enable = true;
        defaultEditor = lib.mkDefault true;
      };
    };
}
