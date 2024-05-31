{pkgs, ...}: {
  imports = [
    ../../terminal/programs/bat.nix
    ../../terminal/programs/btop.nix
    ../../terminal/programs/yazi
    ../../terminal/shell/bash.nix
    ../../terminal/shell/starship.nix
    ../../terminal/emulators/kitty.nix
    ../../programs/gtk.nix
    #../../programs/qt.nix
    ../../programs/utils.nix
    #../../programs/xdg.nix
    ../../programs/zathura.nix
    ../../editors/zed.nix
    ../../editors/nixvim.nix
  ];

  programs.home-manager.enable = true;

  home = {
    username = "simon";
    homeDirectory = "/home/simon";
    sessionVariables = {
      SHELL = "${pkgs.zsh}/bin/zsh";
    };
    stateVersion = "23.11";
  };
  manual = {
    html.enable = false;
    json.enable = false;
    manpages.enable = false;
  };
}
