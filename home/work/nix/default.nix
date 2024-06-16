{pkgs, ...}: {
  imports = [
    ./nix.nix
    ./nixos.nix
    ./nixpkgs.nix
    ./substituters.nix
  ];

  home.packages = with pkgs; [
    cachix
  ];
}
