{
  inputs,
  pkgs,
  ...
}: {
  imports = [
    inputs.ags.homeManagerModules.default
  ];

  home.packages = with pkgs; [
    which
    dart-sass
    fd
    inputs.matugen.packages.${system}.default
    swww
    gnome.gnome-bluetooth_1_0
    bun
  ];

  programs.ags = {
    enable = true;
    configDir = ./style1;
  };
}
