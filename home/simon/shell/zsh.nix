{
  config,
  pkgs,
  ...
}:
{
  programs.zsh = {
    enable = true;
    dotDir = "${config.xdg.configHome}/zsh";
    enableCompletion = true;
    completionInit = "autoload -U compinit && compinit";
    autosuggestion.enable = true;
    autocd = true;
    plugins = [
      {
        # Must be before plugins that wrap widgets, such as zsh-autosuggestions or fast-syntax-highlighting
        name = "fzf-tab";
        src = "${pkgs.zsh-fzf-tab}/share/fzf-tab";
      }
      {
        name = "zsh-nix-shell";
        src = "${pkgs.zsh-nix-shell}/share/zsh-nix-shell/nix-shell.plugin.zsh";
      }
      {
        name = "fast-syntax-highlighting";
        src = "${pkgs.zsh-fast-syntax-highlighting}/share/zsh/site-functions";
      }
      {
        name = "zsh-autosuggestions";
        src = "${pkgs.zsh-autosuggestions}/share/zsh-autosuggestions/zsh-autosuggestions.zsh";
      }
    ];
    syntaxHighlighting = {
      enable = true;
      highlighters = [
        "main"
        "brackets"
        "pattern"
        "root"
      ];
      #patterns = {
      #  "rm *" = "fg=green,bold,bg=red";
      #};
      styles = {
        "g" = "fg=magenta,bold";
        "k" = "fg=cyan,bold";
      };
    };

    initContent = ''
      zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'
      zstyle ':completion:*' menu select
      zstyle ':completion:*' verbose true
      zstyle ':completion:*' completer _complete _ignored _approximate

      # run command
      run() {
          local pkgname="$1"
          local appname="$1"

          if [ -n "$2" ]; then
              appname="$2"
          fi

          nix-shell -p "$pkgname" --run "$appname"
      }
    '';

    history = {
      path = "$ZDOTDIR/.zsh_history";
      share = true;
      expireDuplicatesFirst = true;
      extended = false;
      ignoreDups = true;
      ignoreAllDups = true;
      ignoreSpace = true;
      save = 100000;
      size = 100000;
    };
    envExtra = ''
      setopt no_global_rcs
    '';
  };
}
