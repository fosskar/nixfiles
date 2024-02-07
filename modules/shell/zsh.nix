{pkgs, ...}: {
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    completionInit = "autoload -U compinit && compinit";
    enableAutosuggestions = true;
    autocd = true;
    syntaxHighlighting.enable = true;
    dirHashes = {
      dl = "$HOME/Downloads";
      docs = "$HOME/Documents";
      pics = "$HOME/Pictures";
      vids = "$HOME/Videos";
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
    };
    shellAliases = {
      "cls" = "clear";

      ".." = "cd ..";
      "..." = "cd ../..";
      "...." = "cd ../../..";

      "ll" = "ls -lah -color";
      "la" = "ls -A -color";

      "myip" = "curl http://ipecho.net/plain; echo";

      "code" = "codium";

      "grep" = "grep --color";

      "nix-voyager-deploy" = "nixos-rebuild switch --target-host oscar@nixos-server --use-remote-sudo --upgrade --flake .#voyager";
      "nix-cosmos-deploy" = "sudo nixos-rebuild switch --flake .#cosmos";
    };
  };
}
