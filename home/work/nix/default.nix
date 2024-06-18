{ pkgs, ... }:
{
  imports = [
    ./nix.nix
    ./nixpkgs.nix
  ];

  home.packages = with pkgs; [ cachix ];
}
