_: {
  # enable zsh autocompletion for system packages (systemd, etc)
  environment.pathsToLink = [ "/share/zsh" ];

  programs.zsh = {
    enable = true;
    shellInit = ''
      # Make sure we always use the correct zsh dotdir.
      export ZDOTDIR=$HOME
    '';

    # We actually like zsh completion, but its setup belongs in home-manager
    # configuration to better support standalone home-manager installations. We
    # disable completion here to save time by avoiding duplicate compinit calls
    # and other similar duplications. Despite being disabled here, zsh will be
    # able to complete for my home-manager user.
    # See:
    #  <https://github.com/nix-community/home-manager/issues/3965>
    enableCompletion = false;
  };
}
