{ inputs, pkgs, ... }:
{
  imports = [ inputs.ags.homeManagerModules.ags ];

  home.packages = with pkgs; [
    brightnessctl
    bun
    dart-sass
    hyprpanel
    swww

  ];

  programs.ags = {
    enable = true;
    systemd.enable = true;
  };
}
