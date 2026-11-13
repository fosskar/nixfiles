{ pkgs, ... }:
{
  home.packages = [
    pkgs.protonmail-bridge
    pkgs.teamspeak6-client
  ];
}
