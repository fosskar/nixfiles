{
  config,
  pkgs,
  inputs,
  lib,
  ...
}: {
  imports = [
    ./nh.nix
    ./nix.nix
    ./nixos.nix
    ./nixpkgs.nix
    ./substituters.nix
  ];
}
