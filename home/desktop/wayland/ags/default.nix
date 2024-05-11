{
  inputs,
  pkgs,
  ...
}: {
  imports = [
    inputs.ags.homeManagerModules.default
  ];

  home.packages = with pkgs; [
    swww
    brightnessctl
    bun
    dart-sass
    fd
    inputs.matugen.packages.${system}.default
    gnome.gnome-bluetooth_1_0
  ];

  programs.ags = {
    enable = true;
    configDir = ./style1;
  };
}
