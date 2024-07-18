_: {
  # enable zsh autocompletion for system packages (systemd, etc)
  environment.pathsToLink = [ "/share/zsh" ];

  programs = {
    zsh = {
      enable = true;
    };
  };
}
