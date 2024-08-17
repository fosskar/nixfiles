{ inputs, pkgs, ... }:
{
  environment.variables.NIXOS_OZONE_WL = "1";

  # enable hyprland and required options
  programs.hyprland = {
    enable = true;
    package = inputs.hyprland.packages.${pkgs.system}.default;
    portalPackage = inputs.hyprland.packages.${pkgs.system}.xdg-desktop-portal-hyprland;
  };
}
