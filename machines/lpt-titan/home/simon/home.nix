{ pkgs, mylib, ... }:
{
  imports = mylib.scanPaths ./. {
    exclude = [
      "home.nix" # exclude self
    ];
  };

  home = {
    username = "simon";
    homeDirectory = "/home/simon";
    sessionVariables = {
      SHELL = "${pkgs.zsh}/bin/zsh";
    };
    stateVersion = "24.05";
  };

  systemd.user.startServices = "sd-switch";
}
