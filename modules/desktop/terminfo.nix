{ pkgs, lib, ... }:
{
  environment.systemPackages = [
    pkgs.wezterm.terminfo
  ]
  ++ lib.optionals (pkgs.stdenv.hostPlatform == pkgs.stdenv.buildPlatform) [
    pkgs.ghostty.terminfo
  ];
}
