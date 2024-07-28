_: {
  imports = [
    ./aliases.nix
    ./plugins.nix
  ];
  programs.zsh = {
    enable = true;
    dotDir = ".zsh";
    enableCompletion = true;
    completionInit = "autoload -U compinit && compinit";
    autosuggestion.enable = true;
    autocd = true;
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

    dirHashes = {
      dl = "$HOME/Downloads";
      docs = "$HOME/Documents";
      pics = "$HOME/Pictures";
      vids = "$HOME/Videos";
      nix = "$HOME/code/nixfiles";
    };

    initExtra = ''
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
