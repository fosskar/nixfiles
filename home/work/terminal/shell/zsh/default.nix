_: {
  imports = [
    ./aliases.nix
    ./plugins.nix
  ];
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    completionInit = "autoload -U compinit && compinit";
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

    initExtra = ''
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
}
