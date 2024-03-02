{pkgs, ...}: {
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    completionInit = "autoload -U compinit && compinit";
    enableAutosuggestions = true;
    autocd = true;
    syntaxHighlighting = {
      enable = true;
      highlighters = ["main" "brackets" "pattern" "cursor" "regexp" "root" "line"];
    };
    dirHashes = {
      dl = "$HOME/Downloads";
      docs = "$HOME/Documents";
      pics = "$HOME/Pictures";
      vids = "$HOME/Videos";
      nix = "$HOME/nixfiles";
    };
    initExtra = ''
      zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'
      zstyle ':completion:*' menu select
      zstyle ':completion:*' verbose true
      zstyle ':completion:*' completer _complete _ignored _approximate
    '';
    history = {
      expireDuplicatesFirst = true;
      extended = true;
      ignoreDups = true;
      ignoreSpace = true;
    };
    shellAliases = {
      cls = "clear";

      ".." = "cd ..";
      "..." = "cd ../..";
      "...." = "cd ../../..";

      ll = "ls -lah -color";
      la = "ls -A -color";

      myip = "curl http://ipecho.net/plain; echo";

      code = "codium";

      grep = "grep --color";

      remote-test-voyager = "nixos-rebuild test --target-host oscar@nixos-server --use-remote-sudo --upgrade --flake .#voyager";
      remote-build-voyager = "nixos-rebuild switch --target-host oscar@nixos-server --use-remote-sudo --upgrade --flake .#voyager";
      test-cosmos = "sudo nixos-rebuild test --flake .#cosmos";
      build-cosmos = "sudo nixos-rebuild switch --flake .#cosmos";

      cleanup = "sudo nix-collect-garbage --delete-older-than 1d";
    };
  };
}
