{ pkgs, ... }:
{
  imports = [
    ./settings.nix
    ./theme.nix
  ];

  home.packages = with pkgs; [
    zed-editor
    nixd
  ];
}
