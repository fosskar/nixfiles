{ lib, ... }:
{
  programs.vim = {
    enable = true;
    defaultEditor = lib.mkDefault true;
  };
}
