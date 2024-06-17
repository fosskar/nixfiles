{ inputs, pkgs, ... }:
let
  agsConfig =
    pkgs.fetchFromGitHub {
      owner = "Aylur";
      repo = "dotfiles";
      rev = "main";
      #sha256 = pkgs.lib.fakeSha256; # used to get the latest hash
      sha256 = "ybp43TjPWnXKcDBnMyN6djysdbq4UPqzEE17/xVxtPY=";
    }
    + "/ags";
in
{
  imports = [ inputs.ags.homeManagerModules.default ];

  home.packages = [
    pkgs.brightnessctl # not working anyway because of OLED
    pkgs.bun
    pkgs.dart-sass
    pkgs.fd
    pkgs.swww
    inputs.matugen.packages.${pkgs.system}.default
  ];

  programs.ags = {
    enable = true;
    configDir = agsConfig;
  };
}
