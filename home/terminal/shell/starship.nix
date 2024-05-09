{config, ...}: {
  home.sessionVariables.STARSHIP_CACHE = "${config.xdg.cacheHome}/starship";

  programs.starship = {
    enable = true;
    enableZshIntegration = true;

    settings = {
      character = {
        success_symbol = "[›](bold green)";
        error_symbol = "[›](bold red)";
      };

      add_newline = true;

      kubernetes = {
        disabled = false;
      };

      nix_shell = {
        symbol = " ";
        heuristic = true;
      };
    };
  };
}
