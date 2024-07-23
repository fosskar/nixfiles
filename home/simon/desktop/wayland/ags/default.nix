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
    pkgs.brightnessctl # not working anyway because of OLED but needed for this ags setup
    pkgs.bun # needed
    pkgs.dart-sass # needed
    pkgs.fd # needed
    pkgs.swww # needed
  ];

  programs.ags = {
    enable = true;
    configDir = agsConfig;
  };
}
