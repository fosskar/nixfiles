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
      hash = "sha256-ZJvnDWCLqNaHbMJCKIHrGo5fHbMqhM2CU7oDF5CnTSs=";
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
