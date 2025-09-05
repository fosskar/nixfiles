{ pkgs, inputs, ... }:
{
  imports = [ inputs.hyprland.nixosModules.default ];

  environment = {
    systemPackages = with pkgs; [ hyprpolkitagent ];
  };

  programs.hyprland = {
    enable = true;
    package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
    portalPackage =
      inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland;
    #withUWSM = true; # not reccomended anymore
  };
}
