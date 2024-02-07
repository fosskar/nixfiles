{pkgs, ...}: {
  imports = [
    ../../modules/shell/starship.nix
    ../../modules/shell/zsh.nix
  ];

  programs.home-manager.enable = true;

  home = {
    username = "oscar";
    homeDirectory = "/home/oscar";
  };

  home.stateVersion = "23.11";
}
