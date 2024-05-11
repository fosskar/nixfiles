{config, ...}: {
  home.sessionVariables.STARSHIP_CACHE = "${config.xdg.cacheHome}/starship";

  programs.starship = {
    enable = true;
    enableZshIntegration = true;

    settings = {
      scan_timeout = 2;
      command_timeout = 2000;
      add_newline = true;
      character = {
        success_symbol = "[](bold green)";
        error_symbol = "[](bold red)";
        vicmd_symbol = "[](bold yellow)";
        format = "$symbol [|](bold bright-black) ";
      };

      directory = {
        format = "[ ](bold green) [$path]($style) ";
      };

      hostname = {
        ssh_only = true;
        disabled = false;
        format = "@[$hostname](bold blue) "; # the whitespace at the end is actually important
      };

      kubernetes = {
        disabled = false;
      };

      nix_shell = {
        symbol = "[ ](blue) ";
        heuristic = true;
      };
      git_commit.commit_hash_length = 7;
      git_branch.style = "bold purple";
      git_status = {
        style = "red";
        ahead = "⇡ ";
        behind = "⇣ ";
        conflicted = " ";
        renamed = "»";
        deleted = "✘ ";
        diverged = "⇆ ";
        modified = "!";
        stashed = "≡";
        staged = "+";
        untracked = "?";
      };
      lua.symbol = "[ ](blue) ";
      python.symbol = "[ ](blue) ";
      rust.symbol = "[ ](red) ";
      golang.symbol = "[󰟓 ](blue)";
      c.symbol = "[ ](black)";
      nodejs.symbol = "[󰎙 ](yellow)";
      package.symbol = "📦 ";
    };
  };
}
