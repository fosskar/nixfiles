{...}: {
  imports = [
    ../../shell/starship.nix
    ../../shell/zsh.nix
  ];

  programs.home-manager.enable = true;

  home = {
    username = "oscar";
    homeDirectory = "/home/oscar";
    sessionVariables = {
      TERM = "xterm-256color";
    };
    stateVersion = "23.11";
  };
}
