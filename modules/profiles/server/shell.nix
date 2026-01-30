{ pkgs, ... }:
{
  # zellij for session persistence over ssh
  environment.systemPackages = [ pkgs.zellij ];

  # servers use system zsh with full completion (no home-manager)
  programs.zsh = {
    interactiveShellInit = ''
      # auto-start zellij on ssh login
      if [[ -z "$ZELLIJ" && -n "$SSH_TTY" ]]; then
        zellij attach -c default
      fi
    '';
    enableGlobalCompInit = true;
    enableCompletion = true;
    enableBashCompletion = true;
    autosuggestions.enable = true;
    syntaxHighlighting = {
      enable = true;
      patterns."rm -rf *" = "fg=black,bg=red";
      styles.alias = "fg=magenta";
      highlighters = [
        "main"
        "brackets"
        "pattern"
      ];
    };
  };
}
