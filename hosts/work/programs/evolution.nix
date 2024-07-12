{ pkgs, ... }:
{
  programs.evolution = {
    enable = true;
    plugins = [ pkgs.evolution-ews ];
  };
}
