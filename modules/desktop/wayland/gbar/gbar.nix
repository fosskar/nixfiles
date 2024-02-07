{
  inputs,
  lib,
  pkgs,
  hyprland,
  ...
}: {
  imports = [inputs.gBar.homeManagerModules.x86_64-linux.default];

  programs.gBar = {
    enable = true;
  };
}
