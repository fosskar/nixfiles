{ config, ... }:
{
  home.sessionVariables.STARSHIP_CACHE = "${config.xdg.cacheHome}/starship";

  programs.starship = {
    enable = true;
    enableZshIntegration = true;
    enableBashIntegration = true;

    settings = {
      add_newline = true;
      hostname = {
        ssh_only = true;
        disabled = false;
        format = "@[$hostname](bold blue) "; # the whitespace at the end is actually important
      };

      kubernetes = {
        disabled = false;
      };

      git_commit.commit_hash_length = 7;
      git_branch.style = "bold purple";
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
