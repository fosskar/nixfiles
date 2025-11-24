{ inputs, pkgs, ... }:
{
  imports = [
    inputs.dms.nixosModules.greeter
  ];
  programs.dankMaterialShell.greeter = {
    enable = false;
    compositor.name = "hyprland"; # or set to hyprland
    configHome = "/home/simon";
    quickshell.package = inputs.quickshell.packages.${pkgs.stdenv.hostPlatform.system}.default;
  };
}
