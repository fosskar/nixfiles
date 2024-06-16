{
  inputs,
  pkgs,
  ...
}: let
  agsConfig =
    pkgs.fetchFromGitHub {
      owner = "Aylur";
      repo = "dotfiles";
      rev = "main";
      #sha256 = pkgs.lib.fakeSha256; # used to get the latest hash
      sha256 = "ybp43TjPWnXKcDBnMyN6djysdbq4UPqzEE17/xVxtPY=";
    }
    + "/ags";
in {
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
    configDir = agsConfig;
  };
}
