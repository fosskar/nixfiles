{
  flake.modules.homeManager.zsh =
    { config, pkgs, ... }:
    {
      programs.zsh = {
        plugins = [
          {
            # must be before plugins that wrap widgets
            name = "fzf-tab";
            file = "fzf-tab.plugin.zsh";
            src = "${pkgs.zsh-fzf-tab}/share/fzf-tab";
          }
          {
            name = "nix-shell";
            file = "nix-shell.plugin.zsh";
            src = "${pkgs.zsh-nix-shell}/share/zsh-nix-shell";
          }
          {
            name = "fast-syntax-highlighting";
            file = "fast-syntax-highlighting.plugin.zsh";
            src = "${pkgs.zsh-fast-syntax-highlighting}/share/zsh/site-functions";
          }
          {
            name = "zsh-autosuggestions";
            file = "zsh-autosuggestions.zsh";
            src = "${pkgs.zsh-autosuggestions}/share/zsh-autosuggestions";
          }
          {
            name = "zsh-autopair";
            file = "autopair.zsh";
            src = "${pkgs.zsh-autopair}/share/zsh/zsh-autopair";
          }
        ];
        enable = true;
        dotDir = "${config.xdg.configHome}/zsh";
        enableCompletion = true;
        completionInit = "autoload -Uz compinit && compinit -u";
        autosuggestion.enable = true;
        autocd = true;
        syntaxHighlighting.enable = true;

        dirHashes = {
          dl = "$HOME/Downloads";
          docs = "$HOME/Documents";
          pics = "$HOME/Pictures";
          vids = "$HOME/Videos";
          nix = "$HOME/code/nixfiles";
        };

        initContent = ''
          zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'
          zstyle ':completion:*' menu select
          zstyle ':completion:*' verbose true
          zstyle ':completion:*' completer _complete _ignored _approximate

          if [ -f ~/.zshrc_custom ]; then
            source ~/.zshrc_custom
          fi
        '';

        history = {
          share = true;
          expireDuplicatesFirst = true;
          extended = true;
          ignoreDups = true;
          ignoreSpace = true;
          save = 100000;
          size = 100000;
        };
        envExtra = ''
          setopt no_global_rcs
        '';
      };
    };
}
