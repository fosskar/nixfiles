_: {
  # servers use system zsh with full completion (no home-manager)
  environment.pathsToLink = [ "/share/zsh" ];

  programs = {
    less.enable = true;

    zsh = {
      enable = true;
      enableLsColors = true;
      enableGlobalCompInit = true;
      enableCompletion = true;
      enableBashCompletion = true;
      autosuggestions.enable = true;
      syntaxHighlighting = {
        enable = true;
        patterns = {
          "rm -rf *" = "fg=black,bg=red";
        };
        styles = {
          "alias" = "fg=magenta";
        };
        highlighters = [
          "main"
          "brackets"
          "pattern"
        ];
      };
    };
  };
}
