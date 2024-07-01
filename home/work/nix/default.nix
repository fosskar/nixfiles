{ config, pkgs, ... }:
{
  imports = [
    ./nix.nix
    ./nixpkgs.nix
    ./substituters.nix
  ];

  home.packages = with pkgs; [ cachix ];

  home = {
    sessionVariables.FLAKE = "${config.home.homeDirectory}/code/nixfiles";
  };
}
