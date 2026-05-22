{
  flake.modules.nixos.server =
    { pkgs, ... }:
    {
      # zellij for session persistence over ssh
      environment.systemPackages = [ pkgs.zellij ];

      # servers use system zsh with full completion (no home-manager)
      programs.zsh = {
        promptInit = ''
          PROMPT='%B%F{red}%n@%m%f%b:%F{blue}%~%f %# '
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
    };
}
