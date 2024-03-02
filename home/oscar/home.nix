{pkgs, ...}: {
  imports = [
    ../../modules/home-manager/shell/starship.nix
    ../../modules/home-manager/shell/zsh.nix
  ];

  programs.home-manager.enable = true;

  home.sessionVariables = {
    TERM = "xterm-256color";
  };

  home = {
    username = "oscar";
    homeDirectory = "/home/oscar";
  };

  home.stateVersion = "23.11";
}
