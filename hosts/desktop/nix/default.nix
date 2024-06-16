{ pkgs, ... }:
{
  imports = [
    ./nh.nix
    ./nix.nix
    ./nixos.nix
    ./nixpkgs.nix
    ./substituters.nix
  ];

  environment.systemPackages = with pkgs; [
    git
    cachix
  ];
}
