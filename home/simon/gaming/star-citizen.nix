{ inputs, pkgs, ... }:
{
  home.packages = with pkgs; [ inputs.nix-gaming.packages.${system}.star-citizen-umu ];
}
