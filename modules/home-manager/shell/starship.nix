{config, ...}: {
  programs.starship = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;

    settings = {
      add_newline = true;

      kubernetes = {
        disabled = false;
      };
    };
  };
}
