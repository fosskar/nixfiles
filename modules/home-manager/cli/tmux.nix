{
  flake.modules.homeManager.tmux = _: {
    programs.tmux = {
      enable = true;
      mouse = true;
    };
  };
}
