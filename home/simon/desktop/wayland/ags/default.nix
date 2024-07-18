{ inputs, pkgs, ... }:
let
  agsConfig =
    pkgs.fetchFromGitHub {
      owner = "Aylur";
      repo = "dotfiles";
      rev = "main";
      #sha256 = pkgs.lib.fakeSha256; # used to get the latest hash
      sha256 = "2zDH36hBRnKLwtoYYMhWBaqukm2NMs0t32n1JbSooOE=";
    }
    + "/ags";
in
{
  imports = [ inputs.ags.homeManagerModules.ags ];

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
